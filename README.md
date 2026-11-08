# Respawn

Aplicativo Flutter para descobrir jogos usando a API IGDB. O projeto inclui Android, iOS, Web, Windows, macOS e Linux; os comandos de build dependem das ferramentas oficiais de cada plataforma.

## Requisitos

Use Flutter compatível com a restrição Dart de `pubspec.yaml` e Node.js 20 ou superior. No diretório do projeto:

```bash
flutter pub get
flutter analyze
flutter test
node --test server/index.test.js
```

## Configurar a API IGDB

A IGDB usa OAuth da Twitch. Crie um aplicativo no [Twitch Developer Console](https://dev.twitch.tv/console/apps). Na primeira configuração, copie `.env.example` para `.env` e preencha `TWITCH_CLIENT_ID` e `TWITCH_CLIENT_SECRET` nesse arquivo. O Client ID é de identificação; o Client Secret deve permanecer privado e ambos ficam apenas no servidor:

```powershell
Copy-Item .env.example .env
```

```env
TWITCH_CLIENT_ID=seu-client-id
TWITCH_CLIENT_SECRET=seu-client-secret
LIBRETRANSLATE_URL=http://localhost:5000
LIBRETRANSLATE_API_KEY=
```

O arquivo `.env` é ignorado pelo Git. Inicie o proxy com Node.js 20 ou superior:

```powershell
node --env-file=.env .\server\index.js
```

O proxy escuta na porta `3000` por padrão. Para traduzir sinopses localmente com o LibreTranslate do ZIP, instale o Docker Desktop, extraia o ZIP e abra o PowerShell na pasta que contém `docker-compose.yml`. Inicie o serviço:

```powershell
docker compose up -d
```

Na primeira inicialização, o LibreTranslate baixa os modelos de tradução e pode levar alguns minutos. Ele fica disponível em `http://localhost:5000`; teste esse endereço abrindo a interface no navegador. O proxy usa esse endereço por padrão e não precisa de chave para uma instância local. Se configurou uma chave no LibreTranslate, preencha `LIBRETRANSLATE_API_KEY` no `.env`. Para outro endereço, ajuste `LIBRETRANSLATE_URL`. A tradução acontece ao abrir os detalhes do jogo e fica em cache enquanto o proxy estiver ativo.

Inicie ou reinicie o proxy após configurar `.env`:

```powershell
node --env-file=.env .\server\index.js
```

Em outra janela, inicie o Flutter apontando para ele:

```bash
flutter run --dart-define=IGDB_PROXY_URL=http://localhost:3000/api/games
```

No emulador Android, use `http://10.0.2.2:3000/api/games`; em um dispositivo físico, use o endereço da máquina na rede local. O Android permite HTTP sem TLS somente em builds de debug para facilitar essa configuração local. Para Web, defina `ALLOWED_ORIGIN` com a origem exata do app. O endpoint `GET /health` verifica se o proxy está ativo.

Para release, use um endereço HTTPS público do proxy:

```bash
flutter build apk --release --dart-define=IGDB_PROXY_URL=https://seu-servidor/api/games
```

Para executar no navegador local, use a origem real do app na configuração CORS. Por exemplo:

```powershell
$env:ALLOWED_ORIGIN = "http://localhost:8080"
node --env-file=.env .\server\index.js
```

```bash
flutter run -d web-server --web-port 8080 --dart-define=IGDB_PROXY_URL=http://localhost:3000/api/games
```

Não coloque o Client Secret nem o token OAuth nos `--dart-define` do Flutter: o app é distribuído como cliente público. Configure TLS, restrinja `ALLOWED_ORIGIN` quando usar Web e aplique limites de tráfego no gateway/host em produção. O limite em memória do proxy é por processo e não substitui controles de uma implantação escalável. Se uma versão anterior do projeto expôs credenciais, revogue-as.

## Assinatura e publicação Android

O projeto ainda usa o `applicationId` de exemplo `com.example.respawn`. Antes de publicar, substitua-o por um domínio reverso exclusivo. Para assinar o release, defina `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD` no ambiente do build e mantenha o keystore/credenciais fora do repositório. Sem essas variáveis, o Gradle não assina o artefato; não publique um artefato sem assinatura.

## Notas

- O manifesto principal Android declara acesso à Internet.
- A busca, os gêneros, a ordenação e a paginação são convertidos pelo proxy para a API IGDB.
- Capas de jogos usam imagens verticais; banners e detalhes usam artes horizontais da IGDB quando disponíveis. Imagens usam o cache HTTP do navegador na Web e cache em disco nas demais plataformas.
- A tela de detalhes apresenta a sinopse e as informações disponíveis da IGDB, incluindo notas, lançamento, gêneros e plataformas.
- Sinopses são traduzidas sob demanda pelo LibreTranslate local; a chave opcional fica somente no proxy e nunca é enviada ao app Flutter.
- Erros de API aparecem na interface com opção de tentar novamente; respostas antigas não substituem resultados mais recentes.
- Favoritos permanecem disponíveis ao trocar busca e filtros durante a sessão atual. Ainda não são persistidos após fechar o app.
- Os testes Flutter usam serviço falso, e os testes do proxy usam respostas simuladas; nenhum deles precisa de uma chave ou conexão com a IGDB.
