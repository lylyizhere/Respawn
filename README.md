# Respawn

Aplicativo Flutter para descobrir jogos usando a API RAWG. O projeto inclui Android, iOS, Web, Windows, macOS e Linux; os comandos de build dependem das ferramentas oficiais de cada plataforma.

## Requisitos

Use uma instalação atual do Flutter compatível com a restrição Dart de `pubspec.yaml`. No diretório do projeto:

```bash
flutter pub get
flutter analyze
flutter test
```

## Executar com a API RAWG

Obtenha uma chave de API na RAWG e passe-a como variável de compilação durante a execução:

```bash
flutter run --dart-define=RAWG_API_KEY=SUA_CHAVE
```

Para compilar Android:

```bash
flutter build apk --release --dart-define=RAWG_API_KEY=SUA_CHAVE
```

A chave incluída com `--dart-define` continua podendo ser extraída de um aplicativo cliente. **Isso evita manter a chave em um arquivo versionado, mas não a torna secreta.** Para distribuição pública, a arquitetura recomendada é um backend/proxy que guarde a chave no servidor e aplique limites de uso. A chave presente no ZIP original deve ser revogada e substituída antes de qualquer publicação.

A tela inicial exibe uma mensagem de configuração se a chave não for fornecida.

## Assinatura e publicação Android

O projeto ainda usa o `applicationId` de exemplo `com.example.respawn`. Antes de publicar, substitua-o por um domínio reverso exclusivo. Para assinar o release, defina `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD` no ambiente do build e mantenha o keystore/credenciais fora do repositório. Sem essas variáveis, o Gradle não assina o artefato; não publique um artefato sem assinatura.

## Notas da revisão

- O manifesto principal Android declara acesso à Internet.
- A busca usa parâmetros codificados pela URI, respeita gênero/ordenação e pagina a mesma consulta.
- Erros de API aparecem na interface com opção de tentar novamente; respostas antigas não substituem resultados mais recentes.
- Favoritos permanecem disponíveis ao trocar busca e filtros durante a sessão atual. Ainda não são persistidos após fechar o app.
- Os testes usam serviço falso e não precisam de rede nem de uma chave RAWG.
