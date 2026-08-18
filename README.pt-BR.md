<p align="right"><a href="README.md">English</a></p>

<p align="center"><img src="Assets/Original/social-preview.svg" alt="AI Monitor — monitor CRT retrô original mostrando barras de uso de IA" width="900"></p>

# AI Monitor

**Todo o uso das suas IAs em um pequeno Mac.**

Aplicativo nativo e local para acompanhar limites, horários de renovação, conexão e créditos — somente quando o provedor disponibiliza esses dados oficialmente.

> **Estado atual: MVP em código-fonte.** O app e o widget compilam localmente e os testes unitários passam. Ainda não existe um DMG público assinado e notarizado neste repositório.

## Baixar

[**Download para macOS**](../../releases/latest/download/AI-Monitor.dmg) · [Ver releases](../../releases)

O link passa a funcionar depois da primeira release assinada e notarizada. Até lá, desenvolvedores podem executar o projeto pelo código-fonte.

## Recursos

- popup retrô na barra de menus, sem ícone permanente no Dock;
- várias contas Codex / OpenAI;
- `CODEX_HOME` isolado para cada conta;
- porcentagem restante, janelas primária e secundária e horário de reset;
- atualização manual, cooldown e backoff;
- último valor válido preservado quando uma atualização falha;
- widgets Pequeno e Médio;
- dados locais, credenciais MCP no Keychain e nenhuma telemetria;
- inglês e português do Brasil.

## Provedores

| Provedor | Estado | Observação |
|---|---|---|
| Codex / OpenAI | Disponível no MVP em código | Usa o App Server oficial; não faz scraping |
| Kling | Beta / indisponível | O saldo só será exibido com uma interface oficial de leitura verificada |
| MCP customizado | Base avançada | HTTPS/loopback, token no Keychain e allowlist exata de ferramentas de leitura; editor e SSE ainda planejados |
| Claude, Gemini, Runway e outros | Planejado | Nenhum dado é inventado |

## Instalar uma release

1. Baixe `AI-Monitor.dmg`.
2. Abra o DMG e arraste **AI Monitor.app** para **Applications**.
3. Abra o AI Monitor; ele ficará na barra de menus.
4. Clique em **Add Account → Codex / OpenAI**.
5. Dê um nome à conta e clique em **Sign in with ChatGPT**.
6. Termine o login oficial no navegador.

O AI Monitor precisa do Codex CLI oficial porque o App Server documentado fornece o estado da conta e os limites. O app procura instalações comuns, permite informar um caminho manual e nunca instala software sem consentimento.

## Adicionar o widget

1. Abra o AI Monitor pelo menos uma vez.
2. Clique com o botão direito na Mesa e escolha **Editar Widgets**.
3. Procure **AI Monitor**.
4. Adicione o tamanho Pequeno ou Médio.

O widget não executa login nem inicia o Codex. Quando os dados estiverem antigos, ele pedirá para abrir o aplicativo.

## Privacidade

As contas e os snapshots ficam neste Mac. O AI Monitor não pede nem armazena sua senha do ChatGPT. A autenticação é gerenciada pelo próprio Codex dentro do diretório isolado da conta. Leia [PRIVACY.md](PRIVACY.md) para conhecer os caminhos locais e como apagar tudo.

## Compilar localmente

Requisitos: macOS 14+, Xcode 16 ou mais recente.

```bash
git clone <url-do-repositorio>
cd ai-monitor
./scripts/bootstrap.sh
open AI-Monitor.xcodeproj
./scripts/build.sh
./scripts/test.sh
```

Builds locais não exigem Team ID nem segredos. Compartilhamento real com o widget, assinatura e notarização dependem da configuração descrita em [docs/signing.md](docs/signing.md).

## Dúvidas frequentes

- **É grátis?** Sim. O código usa licença MIT; assinaturas dos provedores são separadas.
- **Envia meus dados para algum servidor próprio?** Não. O AI Monitor não possui backend nem analytics.
- **Guarda minha senha do ChatGPT?** Não. O login oficial acontece no navegador e é gerenciado pelo Codex.
- **Posso usar várias contas Codex?** Sim, com diretórios isolados.
- **O Kling sempre mostra créditos?** Não. Sem interface oficial adequada, aparece “Uso indisponível”.
- **Por que o widget demora?** O WidgetKit controla o agendamento. Abra ou atualize o app para gravar um novo snapshot.
- **Como remover tudo?** Apague o app e siga a seção “Remoção completa” de [PRIVACY.md](PRIVACY.md).
- **Por que o macOS avisa que o app veio da internet?** É uma proteção do Gatekeeper. Use apenas uma release assinada e notarizada ou um build próprio.
- **Onde relato um problema?** Use os formulários de issue e remova secrets dos diagnósticos.
- **Posso adicionar outro provedor?** Sim. Leia [docs/creating-a-provider.md](docs/creating-a-provider.md).

Consulte também [CONTRIBUTING.md](CONTRIBUTING.md), [ROADMAP.md](ROADMAP.md) e [SECURITY.md](SECURITY.md).
