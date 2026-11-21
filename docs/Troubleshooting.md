## 🛠️ Solução de Problemas Comuns (Troubleshooting)

* **`ERR_SSL_PROTOCOL_ERROR` no navegador do cliente:** O navegador está redirecionando automaticamente para `https://`. Digite explicitamente `http://` ou desative a opção *Sempre usar conexões seguras* no navegador.
* **`ERR_ADDRESS_UNREACHABLE`:** Verifique se o Tailscale está conectado em ambos os dispositivos e se não há nenhum *Exit Node* ativado por engano no cliente. Em aparelhos HyperOS, verifique se há *Apps Duplos* ativos interferindo na tabela de rotas VPN.
* **Syncthing mostra "Desconectado" e a opção "Interface web" fica cinza:** O serviço em segundo plano foi pausado pela economia de bateria do Android. Desmarque *Respeitar economia de bateria* nas condições de execução do app e defina a bateria como *Sem restrições* no sistema.
* **Pasta `/cofre` abre sem solicitar senha:** Confirme se o nome da pasta física no celular (`/sdcard/CarbAlium/cofre`) possui exatamente a mesma grafia (maiúsculas/minúsculas) declarada na flag `-v` do comando do Copyparty, e teste o acesso em uma aba anônima para ignorar cookies de sessões anteriores.

*  **Syncthing não sincroniza, mas o servidor está ativo no Termuux:** Verifique as conexões ativas no dispositivo servidor, deve *apenas estar ativo o Wi-fi*, quais quer outras conexões (*Blietooth, Hotspot, Dados Móveis*) Devem permanecer desabilitados.
