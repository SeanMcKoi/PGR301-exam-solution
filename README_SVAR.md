# README_SVAR — PGR301 Eksamen 2026

## Oppgave 1 — Container og CI

### 1A — Containerisér Spring Boot-applikasjonen

`Dockerfile` ligger i repo-roten og er en multi-stage build. Byggesteget bruker Maven og JDK 21 til å lage JAR-filen. `pom.xml` kopieres før kildekoden, slik at avhengighetene caches i et eget lag og senere bygg går raskere. Kjøresteget bruker bare JRE 21 på Alpine og får kun den ferdige JAR-filen. Byggeverktøy og kildekode blir ikke med i sluttimaget, som dermed blir mindre og har færre mulige sårbarheter. Appen kjører som en egen bruker uten root-rettigheter, og `ENTRYPOINT` står i exec-form slik at Java mottar stoppsignaler og kan avslutte pent.

Applikasjonen lytter på port 9999 (`server.port` i `application.properties`, `EXPOSE 9999` i `Dockerfile`).

**Bygg imaget (fra repo-rot):**

```bash
docker build -t wishifai .
```

**Start containeren på localhost:9999:**

AWS-nøkler og konfigurasjon leses fra en lokal `.env`-fil. Lag den fra malen og fyll inn egne nøkler (`.env` er ignorert av både git og Docker):

```bash
cp .env.example .env
```

```bash
docker run --rm -p 9999:9999 --env-file .env wishifai
```

**Test (fra en annen terminal, fra repo-rot):**

```bash
curl -F "image=@samples/sample_image.png" http://localhost:9999/api/analyze
```
