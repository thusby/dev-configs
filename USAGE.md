# Usage Guide

Korleis du bruker `dev-configs` i prosjekta dine.

---

## Python-prosjekt (mcp-common, coordinator, localfarm)

### Alternativ 1: Extend i pyproject.toml (anbefalt)

Legg til i prosjektet sitt `pyproject.toml`:

```toml
[tool.ruff]
extend = "../dev-configs/python/pyproject-base.toml"

[tool.mypy]
extend = "../dev-configs/python/pyproject-base.toml"
```

### Alternativ 2: Import heile fila

```bash
cd prosjektet-ditt/
ln -s ../dev-configs/python/pyproject-base.toml pyproject.toml
```

**NB:** Dette fungerer berre om du ikkje har prosjekt-spesifikke `[project]` seksjoner.

### Alternativ 3: Kopier og tilpass

```bash
cp ../dev-configs/python/pyproject-base.toml pyproject.toml
# Rediger pyproject.toml for prosjekt-spesifikke innstillingar
```

---

## C/C++ Embedded-prosjekt (zephyr-meta)

### Bruk setup-skriptet

```bash
cd zephyr-meta/
../dev-configs/setup.sh c-embedded .
```

Dette linkar:
- `.clang-format` - C/C++ formatering (Zephyr-stil)
- `.editorconfig` - Editor-innstillingar

### Manuell linking

```bash
cd zephyr-meta/
ln -s ../dev-configs/c-embedded/.clang-format .clang-format
ln -s ../dev-configs/c-embedded/.editorconfig .editorconfig
```

---

## Node.js/Vue.js-prosjekt (localfarm frontend)

### Bruk setup-skriptet

```bash
cd localfarm/platform/frontend/
../../../dev-configs/setup.sh node .
```

Dette linkar:
- `.gitignore` - Node.js gitignore-mal

**Status:** ESLint/Prettier configs er ikkje implementert enno.

---

## .gitignore-malar

### Python-prosjekt

```bash
cd prosjektet-ditt/
ln -s ../dev-configs/git/python.gitignore .gitignore
```

### Node.js-prosjekt

```bash
cd prosjektet-ditt/
ln -s ../dev-configs/git/node.gitignore .gitignore
```

---

## Oppdatere configs

Når du oppdaterer filer i `dev-configs`:

1. **Test i eitt prosjekt først:**
   ```bash
   cd mcp-common/
   ruff check .
   mypy .
   pytest
   ```

2. **Commit med god beskrivelse:**
   ```bash
   git commit -m "ruff: enable N (pep8-naming) rules

   Affects: mcp-common, coordinator, localfarm backend"
   ```

3. **Oppdater prosjekt som bruker det:**
   ```bash
   cd mcp-common/
   git pull  # Får automatisk oppdaterte configs via symlinks
   ```

---

## Verifisere symlinks

```bash
# Sjekk om filer er symlinks
ls -la prosjektet/.clang-format

# Output skal vise: .clang-format -> ../dev-configs/c-embedded/.clang-format
```

---

## Feilsøking

### Problem: "extend" funkar ikkje i pyproject.toml

**Løysing:** Bruk absolutt sti eller relativ frå prosjektrot:

```toml
[tool.ruff]
extend = "../dev-configs/python/pyproject-base.toml"
```

### Problem: Symlink viser feil sti

**Løysing:** Bruk absolutt sti:

```bash
ln -s /home/thusby/Development/projects/dev-configs/c-embedded/.clang-format .clang-format
```

### Problem: clang-format fungerar ikkje

**Sjekk:**
```bash
clang-format --version  # Må vere ≥10
which clang-format
```

---

## Best Practices

1. **Alltid test config-endringar** i eitt prosjekt før du commit
2. **Dokumenter kvifor** du endrar ein regel i commit-meldinga
3. **Sjekk kva prosjekt som påverkas** før du gjer breaking changes
4. **Bruk extend når mogleg** i staden for å kopiere heile filer
5. **Hald README.md oppdatert** når du legg til nye configs

---

## Framtidige utvidingar

- [ ] ESLint config for JavaScript/TypeScript
- [ ] Prettier config for frontend-prosjekt
- [ ] GitHub Actions reusable workflows
- [ ] DevContainer templates
- [ ] Docker Compose snippets
- [ ] Ansible role templates
