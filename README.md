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

## Iniciar o LibreTranslate local

1. Baixe e instale o [Docker Desktop para Windows](https://www.docker.com/products/docker-desktop/) e abra-o. Reinicie o computador se o instalador solicitar.
2. No PowerShell, inicie o LibreTranslate em segundo plano:

   ```powershell
   docker run -d --name libretranslate --restart unless-stopped -p 5000:5000 libretranslate/libretranslate
   ```

   O Docker baixa a imagem na primeira execução. O LibreTranslate usa configurações padrão sem exigir chave de API; não acrescente `--api-keys false` — `--api-keys` é uma opção sem argumento, que habilita chaves quando usada.

3. Aguarde o carregamento ou download inicial dos modelos de tradução e confira os logs:

   ```powershell
   docker logs -f libretranslate
   ```

   Quando o serviço estiver pronto, abra `http://localhost:5000` no navegador. Para sair da visualização dos logs sem parar o serviço, pressione `Ctrl+C`.

   Para parar e iniciar o container depois:

   ```powershell
   docker stop libretranslate
   docker start libretranslate
   ```

O Docker precisa de internet para baixar a imagem e os modelos inicialmente; depois, traduções podem ser processadas localmente com os modelos já carregados. Isso não torna o Respawn inteiro offline: a consulta de jogos à IGDB ainda precisa de conexão. O uso local evita uma cota de caracteres de um provedor de tradução hospedado, mas não garante uso ilimitado — há limites de hardware e de configuração do serviço.

## Iniciar o proxy e o app

1. A IGDB usa OAuth da Twitch. Crie um aplicativo no [Twitch Developer Console](https://dev.twitch.tv/console/apps). Copie `.env.example` para `.env` e substitua os valores de exemplo pelas chaves reais da sua conta:

   ```powershell
   if (-not (Test-Path .env)) { Copy-Item .env.example .env }
   ```

   Nunca versione credenciais reais. O arquivo `.env` deve permanecer local e privado, e as variáveis do Twitch devem ter valores válidos antes de iniciar o proxy. Não é necessário adicionar configurações do LibreTranslate ao `.env` para uso local: por padrão, o proxy acessa `http://localhost:5000` sem chave. Se você alterar a porta/endereço do LibreTranslate ou ativar autenticação, configure `LIBRETRANSLATE_URL` e, se necessário, `LIBRETRANSLATE_API_KEY` no `.env`.

2. Em um terminal na pasta do Respawn, inicie o proxy:

   ```powershell
   node --env-file=.env .\server\index.js
   ```

   O proxy escuta na porta `3000` e encaminha traduções para o LibreTranslate na porta `5000`. Verifique o proxy abrindo `http://localhost:3000/health`; a resposta deve ser `{"status":"ok"}`.

3. Em outro terminal na pasta do Respawn, inicie o Flutter. O pacote `http` já está declarado no `pubspec.yaml`; não precisa adicioná-lo novamente.

   Windows, Web ou outro dispositivo que consiga acessar o proxy pelo próprio `localhost`:

   ```powershell
   flutter run --dart-define=IGDB_PROXY_URL=http://localhost:3000/api/games
   ```

   Emulador Android:

   ```powershell
   flutter run --dart-define=IGDB_PROXY_URL=http://10.0.2.2:3000/api/games
   ```

   Em um celular físico, substitua `localhost` pelo endereço IP local do computador que executa o proxy e permita o acesso à porta `3000` no firewall, se necessário. O app não precisa acessar a porta `5000`; ela é usada pelo proxy no próprio computador.

O Flutter envia tanto as consultas de jogos quanto os pedidos de tradução ao proxy Respawn (`/api/games` e `/api/translate`). O proxy, executado no computador, acessa o LibreTranslate em `localhost:5000`. **Não configure a URL do Flutter diretamente para `localhost:5000`**: no emulador Android, `localhost` aponta para o próprio emulador; além disso, a tradução já está integrada no serviço existente do app.

Para remover o container do LibreTranslate, pare-o primeiro e então execute `docker rm libretranslate`. Para release, publique o proxy com HTTPS e use a URL HTTPS pública:

```powershell
flutter build apk --release --dart-define=IGDB_PROXY_URL=https://seu-servidor/api/games
```

Para executar no navegador local, use a origem real do app na configuração CORS. Por exemplo, no terminal do proxy:

```powershell
$env:ALLOWED_ORIGIN = "http://localhost:8080"
node --env-file=.env .\server\index.js
```

E em outro terminal:

```powershell
flutter run -d web-server --web-port 8080 --dart-define=IGDB_PROXY_URL=http://localhost:3000/api/games
```

Não coloque o Client Secret nem o token OAuth nos `--dart-define` do Flutter: o app é distribuído como cliente público. Configure TLS, restrinja `ALLOWED_ORIGIN` quando usar Web e aplique limites de tráfego no gateway/host em produção. O limite em memória do proxy é por processo e não substitui controles de uma implantação escalável. Se uma versão anterior do projeto expôs credenciais, revogue-as.

## Assinatura e publicação Android

O projeto ainda usa o `applicationId` de exemplo `com.example.respawn`. Antes de publicar, substitua-o por um domínio reverso exclusivo. Para assinar o release, defina `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD` no ambiente do build e mantenha o keystore/credenciais fora do repositório. Sem essas variáveis, o Gradle não assina o artefato; não publique um artefato sem assinatura.

## Notas

- O manifesto principal Android declara acesso à Internet.
- A tela inicial prioriza jogos com lançamento completo já ocorrido, ordenados pela data mais recente; títulos futuros e em acesso antecipado não entram nessa lista. O corte usa o dia local do dispositivo para não tratar a meia-noite UTC da IGDB como horário real de lançamento. Mais resultados são carregados automaticamente durante a rolagem, antecipando a próxima consulta para reduzir esperas no fim da lista. A busca, os gêneros, a ordenação e os lotes de resultados são convertidos pelo proxy para a API IGDB. Buscas usam a relevância padrão da IGDB, que não aceita ordenação explícita na mesma consulta.
- Capas de jogos usam imagens verticais; banners e detalhes usam artes horizontais da IGDB quando disponíveis. Imagens usam o cache HTTP do navegador na Web e cache em disco nas demais plataformas.
- Datas de lançamento priorizam a data marcada como lançamento efetivo pela IGDB e são exibidas como `dd/mm/aaaa` nos cards e detalhes. Quando a IGDB informa apenas mês ou ano, o dia é preenchido como `01`.
- A tela de detalhes apresenta a sinopse e as informações disponíveis da IGDB, incluindo notas, lançamento, gêneros e plataformas.
- Ao abrir os detalhes, a sinopse é traduzida automaticamente para português pelo LibreTranslate local. Se a tradução falhar, o texto original continua visível e a tela oferece uma opção para tentar novamente; a chave opcional fica somente no proxy e nunca é enviada ao app Flutter.
- Erros de API aparecem na interface com opção de tentar novamente; respostas antigas não substituem resultados mais recentes.
- Favoritos permanecem disponíveis ao trocar busca e filtros durante a sessão atual. Ainda não são persistidos após fechar o app.
- Os testes Flutter usam serviço falso, e os testes do proxy usam respostas simuladas; nenhum deles precisa de uma chave ou conexão com a IGDB.
