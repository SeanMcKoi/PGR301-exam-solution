# README - PGR301 Eksamen 2026

Kandidatnummer: **54**

Følgende dokumentasjon dekker besvarelsen for eksamen i PGR301. 
Alle kommandoer forutsettes kjørt fra root med mindre annet er spesifisert.

---

## Oppgave 1 - Container og CI

### 1A - Containerisering

For lokal kjøring og verifisering av applikasjonen benyttes følgende flyt:

```bash
cp .env.example .env          # Konfigurer egne AWS-nøkler
docker build -t wishifai .
docker run --rm -p 9999:9999 --env-file .env wishifai
curl -F "image=@samples/sample_image.png" http://localhost:9999/api/analyze

```

Docker-arkitekturen er implementert som en *multi-stage build* for å separere bygge- og kjøremiljøet.
Byggesteget benytter Maven og JDK 21 til å kompilere kildekoden til en eksekverbar JAR-fil.
Ved å kopiere `pom.xml` før øvrig kildekode, blir prosjektets avhengigheter cachet i et eget lag, 
noe som optimerer byggetiden ved senere endringer.
Kjøresteget baserer seg på en minimal JRE 21-runtime på Alpine Linux som kun mottar den ferdige artefakten.
Dette reduserer både image-størrelse og angrepsflate betraktelig.

Applikasjonen kjører med en dedikert bruker uten root-rettigheter, og `ENTRYPOINT` er definert i *exec-form* for å sikre 
at Java-prosessen fanger opp operativsystemets `SIGTERM`-signaler og avsluttes kontrollert.
Flagget `-DskipTests` er inkludert under bygging fordi enhetstestene krever tilgang til eksterne AWS-tjenester som ikke er tilgjengelige i build-konteksten.

Tjenesten lytter på port 9999 (`server.port=9999`), hvilket sikrer konsistent portbruk på tvers av lokal kjøring og ECS.
Sensitiv konfigurasjon håndteres via `.env`, som er ekskludert fra versjonskontroll; kun malen `.env.example` inkluderes i repositoryet.
I produksjonsmiljøet (ECS) benyttes IAM task-rollen for autentisering snarere enn statiske nøkler.

### 1B - CI-pipeline til ECR

*Vellykket kjøring:* [GitHub Actions Run](https://github.com/SeanMcKoi/PGR301-exam-solution/actions/runs/41046462788)

Pipelinen definert i `.github/workflows/ci.yml` utløses ved push til `main`.
Den autentiserer mot AWS via GitHub Secrets, bygger containerimaget og publiserer det til ECR-repositoriet `wishifai-54`.

Imaget tagges med både full commit-SHA og `latest`.
Commit-SHA-en fungerer som en uforanderlig peker til den spesifikke koden imaget ble bygget fra, noe som sikrer full sporbarhet og forenkler eventuell rollback.
`latest`-taggen benyttes kun lokalt for enkel henting og utelates fra deploy-prosessen. 
Semantisk versjonering ble vurdert, men kontinuerlig leveranse direkte fra `main` gjør at commit-SHA dekker behovet for sporbarhet automatisk.

---

## Oppgave 2 - ECS Express med Terraform

### 2A - Infrastruktur for tjenesten

*Offentlig endepunkt:* [AWS ECS Service URL](https://wi-2b51b7f8849b40479605fee85ad716bc.ecs.eu-west-1.on.aws)

Infrastrukturen provisjoneres via Terraform fra `infra/`-mappen:

```bash
cd infra && terraform init && terraform apply && terraform output service_url

```

Konfigurasjonen er strukturert med variabler for region, kandidatnummer, image-tag og ECR-repositorium, 
der kandidatnummeret benyttes som suffiks for å unngå navnekollisjoner i felles AWS-konto. 
ECS-tjenesten benytter standardrollene `ecsTaskExecutionRole` og `ecsInfrastructureRoleForExpressServices`, \n
med helsesjekk mot `/actuator/health` og `wait_for_steady_state = true` for å sikre verifisert oppstart.

S3-bøtten `wishifai-uploads-54` er opprettet med blokkert offentlig tilgang, og navnet overføres dynamisk til containeren via miljøvariabel.
IAM task-rollen `wishifai-task-role-54` er begrenset i henhold til prinsippet om minste privilegium: 
`s3:PutObject` er avgrenset til egen bøtte (da Rekognition mottar binærdata direkte), 
og tillatelser gis for `rekognition:DetectLabels`, `bedrock:InvokeModel` samt `cloudwatch:PutMetricData`.

### 2B - Remote State og Versjonering

Terraform-tilstanden lagres sentralt i S3-bøtten `pgr301-terraform-state` under stien `wishifai/54/terraform.tfstate`.
Tilstandslåsing er aktivert via `use_lockfile = true` (krever Terraform $\ge 1.10$) for å forhindre samtidige endringer, 
og state-filen krypteres med `encrypt = true`. Provider-versjoner låses gjennom innsjekking av `.terraform.lock.hcl`.

### 2C - Terraform i GitHub Actions

*Vellykket kjøring:* [GitHub Actions Run - Terraform](https://github.com/SeanMcKoi/PGR301-exam-solution/actions/runs/42857588158)

Pipelinen integrerer Terraform som et oppfølgende steg etter at imaget er publisert (`needs: build-and-push`). 
Dette sikrer at infrastrukturen kun oppdateres dersom kildekoden bygger og pushes uten feil, og at tjenesten alltid peker på en gyldig og eksisterende image-tag i ECR. 
Rekkefølgen forhindrer at ECS forsøker å hente et bilde som ennå ikke eksisterer, og gir en ren kobling mellom commit, bilde og distribusjon.