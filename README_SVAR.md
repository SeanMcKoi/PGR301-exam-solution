# README_SVAR - PGR301 Eksamen 2026

Kandidatnummer: **54**

Kommandoene kjøres fra repo-roten med mindre noe annet står.

---

## Oppgave 1 - Container og CI

### 1A - Containerisering

```bash
cp .env.example .env          # fyll inn egne AWS-nøkler
docker build -t wishifai .
docker run --rm -p 9999:9999 --env-file .env wishifai
curl -F "image=@samples/sample_image.png" http://localhost:9999/api/analyze
```

Dockerfilen er en **multi-stage build**:

- **Byggesteget** (Maven + JDK 21) lager JAR-filen. `pom.xml` kopieres før kildekoden, så avhengighetene caches i et eget lag og senere bygg går raskere.
- **Kjøresteget** (JRE 21 på Alpine) får bare den ferdige JAR-filen. Byggeverktøy og kildekode blir ikke med, så imaget blir mindre og har færre mulige sårbarheter.
- **Ikke root:** appen kjører som en egen bruker uten root-rettigheter.
- **Exec-form:** `ENTRYPOINT` står i exec-form, slik at Java mottar `SIGTERM` og kan avslutte pent.

`-DskipTests` brukes fordi testene ville trengt AWS-tilgang inne i bygget. I et større team ville jeg kjørt testene som et eget steg i pipelinen.

Appen lytter på **9999 overalt** (`server.port=9999`), slik at containeren, lokal kjøring og ECS bruker samme port. Nøklene leses fra `.env`, som er ignorert av både git og Docker. Bare malen `.env.example` committes. I ECS trengs ingen nøkler, fordi appen får tilgang gjennom task-rollen (se 2A).

### 1B - CI-pipeline til ECR

**Grønn kjøring:** <https://github.com/SeanMcKoi/PGR301-exam-solution/actions/runs/41046462788>

`.github/workflows/ci.yml` kjører **kun ved push til `main`**. Den logger inn på AWS med nøkler fra GitHub Secrets, bygger imaget og pusher det til ECR-repoet `wishifai-54`. Repoet er opprettet manuelt med AWS CLI.

**Tagging-strategi:** hvert image tagges med **full commit-SHA** og `latest`.

- **Commit-SHA:** peker på nøyaktig koden imaget ble bygget fra og overskrives aldri. Dermed er det alltid sporbart hva som kjører, og rollback betyr å deploye en tidligere SHA. Det er denne taggen Terraform deployer.
- **`latest`:** bare en snarvei for å trekke nyeste versjon lokalt. Den brukes ikke til deploy, fordi den flytter seg ved hver push.
- **Semantisk versjonering:** vurdert, men det krever manuell versjonering. Med kontinuerlig deploy fra `main` gir SHA-en samme sporbarhet automatisk.

---

## Oppgave 2 - ECS Express med Terraform

### 2A - Infrastruktur for tjenesten

**Offentlig URL:** <https://wi-2b51b7f8849b40479605fee85ad716bc.ecs.eu-west-1.on.aws>

```bash
curl -F "image=@samples/sample_image.png" \
  https://wi-2b51b7f8849b40479605fee85ad716bc.ecs.eu-west-1.on.aws/api/analyze
```

Terraform-koden ligger i `infra/`, med én fil per ansvarsområde (`s3.tf`, `iam.tf`, `ecs.tf`, `variables.tf`, `outputs.tf`, `providers.tf`):

```bash
cd infra && terraform init && terraform apply && terraform output service_url
```

- **Variabler:** `region`, `candidate_number`, `image_tag` og `ecr_repository`. Alle ressursnavn får kandidatnummeret som suffiks, siden kontoen deles av hele klassen. Pipelinen sender inn commit-SHA som `image_tag`, så nøyaktig det imaget som nettopp ble bygget blir deployet.
- **Tjenesten** bruker de oppgitte rollene `ecsTaskExecutionRole` og `ecsInfrastructureRoleForExpressServices`.
  - `container_port = 9999` stemmer med appen.
  - Helsesjekken går mot `/actuator/health`.
  - `wait_for_steady_state = true` gjør at `apply` feiler hvis containeren ikke blir sunn, i stedet for å gi en falsk grønn pipeline.
- **S3-bucket:** `wishifai-uploads-54`, med all offentlig tilgang blokkert. `S3_BUCKET` settes automatisk på containeren fra bucket-ressursen, så navnet bare finnes ett sted. `force_destroy` gjør opprydding enkelt her, men ville blitt fjernet i produksjon.
- **Task-rolle** (`wishifai-task-role-54`) med minste privilegium, basert på AWS-kallene appen faktisk gjør:
  - `s3:PutObject`, kun på egen bucket. Rekognition får bildet som bytes, så lesetilgang trengs ikke.
  - `rekognition:DetectLabels`
  - `bedrock:InvokeModel` på modeller og inferensprofiler. `eu.`-profilen ruter til flere EU-regioner.
  - `cloudwatch:PutMetricData` for metrikker fra Micrometer.
  - Rekognition og CloudWatch støtter ikke ressursbegrensning for disse handlingene, så de har `*`.
