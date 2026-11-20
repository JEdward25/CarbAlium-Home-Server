# ☁️ CarbAlium — Servidor Cloud & NAS Pessoal em Smartphone Android

O **CarbAlium** é uma arquitetura de nuvem pessoal privada e auto-hospedada (*self-hosted*), projetada para transformar um smartphone Android (testado em **Redmi 13C / HyperOS**) em um servidor de arquivos 24/7 acessível de qualquer lugar com criptografia ponta a ponta, transferência via navegador, montagem de unidade de rede (WebDAV) e sincronização bidirecional automática.

---

## 🏗️ Arquitetura e Stack Tecnológica

A comunicação entre o servidor e os clientes ocorre exclusivamente através de uma rede privada virtual em malha (*Mesh VPN*), eliminando a necessidade de abrir portas no roteador (*Port Forwarding*), lidar com CGNAT ou depender de IPs dinâmicos de operadoras.

```text
+-------------------------------------------------------------------+
|                   SERVIDOR: Redmi 13C (HyperOS)                   |
|                                                                   |
|  [ Termux + Copyparty ]  ---> Porta 3923 (Web UI & WebDAV)        |
|  [ Syncthing-Fork     ]  ---> Porta 22000 (Sincronização P2P)     |
|  [ Tailscale VPN      ]  ---> IP Fixo Mesh (100.x.y.z)            |
+---------------------------------+---------------------------------+
                                  |
                     Túnel Criptografado WireGuard
                                  |
         +------------------------+------------------------+
         |                                                 |
         v                                                 v
+---------------------------------+       +---------------------------------+
|      CLIENTE: PC (Windows)      |       |   CLIENTE: Tablet / Celular     |
|                                 |       |                                 |
| • Tailscale Client              |       | • Tailscale App                 |
| • Unidade de Rede K: (WebDAV)   |       | • Web App / PWA (Navegador)     |
| • Navegador Web                 |       | • Syncthing-Fork                |
| • Syncthing                     |       |                                 |
+---------------------------------+       +---------------------------------+
```

### Componentes Principais
* **[Termux](https://termux.dev/):** Ambiente terminal Linux para Android responsável por hospedar o servidor web.
* **[Copyparty](https://github.com/9001/copyparty):** Servidor leve de arquivos em Python com suporte a HTTP, WebDAV, controle de acesso granular por pasta e interface web responsiva.
* **[Syncthing-Fork](https://github.com/Catfriend1/syncthing-android):** Motor de sincronização contínua ponto a ponto (*P2P*) entre pastas locais dos dispositivos.
* **[Tailscale](https://tailscale.com/):** Rede Mesh VPN baseada em WireGuard que atribui um endereço IP fixo (`100.x.y.z`) para cada dispositivo da rede.

---

## 📱 Parte 1: Configuração do Dispositivo Servidor (Android / HyperOS)

Para garantir que o servidor permaneça online de forma ininterrupta (inclusive durante a madrugada e ciclos de carregamento na tomada), siga as etapas abaixo na ordem apresentada.

### 1.1. Blindagem de Energia, Memória e Processos (HyperOS / Android)

Sistemas Android modernos — especialmente o HyperOS/MIUI — encerram processos em segundo plano para economizar bateria. Configure os aplicativos **Termux**, **Tailscale** e **Syncthing-Fork** com as seguintes regras:

1. **Permissões individuais dos 3 apps** (Segure o ícone do app > *Informações do app*):
   * **Inicialização automática:** `Ativada`
   * **Economia de bateria:** `Sem restrições`
   * **Tela de Aplicativos Recentes:** Abra os três apps, acesse a multitarefa, segure o dedo sobre cada janela e toque no ícone de **Cadeado 🔒** para fixá-los na RAM.
2. **Desativar o corte noturno do HyperOS:**
   * Acesse **Configurações > Bateria > Engrenagem (canto superior direito)**.
   * **Desative** *Otimização de espera durante o sono* (evita quedas de rede e encerramento de processos durante a madrugada).
   * Em *Limpar cache quando o dispositivo estiver bloqueado*, selecione **Nunca**.
3. **Evitar picos de RAM ao conectar o carregador:**
   * Abra a **Google Play Store > Perfil > Configurações > Preferências de rede > Atualizar apps automaticamente** e marque **Não atualizar apps automaticamente**.
4. **Desativar o *Phantom Process Killer* do Android:**
   * Ative as **Opções do desenvolvedor** (*Configurações > Sobre o telefone > toque 7x em Versão do OS*).
   * Em **Configurações adicionais > Opções do desenvolvedor**, ative **Desativar restrições de processos filhos** (*Disable child process restrictions*).
   * *Alternativa via PC (caso a opção não apareça no menu):* Conecte o celular via USB com Depuração USB ativa e execute:
     ```bash
     adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
     ```
5. **Estabilidade de Rádio (Wi-Fi vs. Bluetooth):**
   * Em aparelhos onde Wi-Fi 2,4 GHz e Bluetooth compartilham a mesma antena, mantenha o **Bluetooth desligado** no servidor.
   * Vá em **Configurações > Localização > Serviços de localização** e desative **Busca por Bluetooth** e **Busca por Wi-Fi**.
   * Sempre que possível, conecte o servidor à rede Wi-Fi de **5 GHz**.

---

### 1.2. Configuração da Rede VPN no Servidor (Tailscale)

1. Instale o **Tailscale** no smartphone servidor e faça login na sua conta.
2. No painel web administrativo do Tailscale (`https://login.tailscale.com/admin/machines`), localize o dispositivo servidor, clique no menu **`...`** e selecione **Disable key expiry** (impede que a chave VPN expire após 180 dias).
3. Anote o **IPv4 do Tailscale** atribuído ao servidor (ex.: `100.64.239.18`).
4. No Android do servidor, vá em **Configurações > Mais opções de conectividade > VPN**, toque na engrenagem ao lado do **Tailscale** e ative **VPN sempre ativa** (*Always-on VPN*).

---

### 1.3. Instalação e Configuração do Copyparty (Termux)

1. Instale o **Termux** (preferencialmente via F-Droid ou GitHub Releases oficial) e conceda acesso ao armazenamento:
   ```bash
   termux-setup-storage
   ```
2. Atualize os pacotes e instale o Python e o Copyparty:
   ```bash
   pkg update && pkg upgrade -y
   pkg install python -y
   pip install --upgrade copyparty
   ```
3. Crie a estrutura de diretórios no armazenamento interno do aparelho:
   ```bash
   mkdir -p /sdcard/CarbAlium/cofre
   ```
   > **Atenção:** Respeite exatamente letras maiúsculas e minúsculas no nome da pasta `cofre`, pois o Copyparty diferencia maiúsculas de minúsculas nas regras de URL.
4. Ative o *Wake-Lock* para impedir que a CPU entre em sono profundo:
   ```bash
   termux-wake-lock
   ```
   *(Também é possível ativar tocando em **Acquire wakelock** na notificação persistente do Termux).*

#### Comando de Inicialização (Produção com Dois Níveis de Acesso)

O comando abaixo define o nome fixo do servidor (`--name CarbAlium`), cria duas contas distintas (`admin` e `cofre`), restringe a raiz `/` apenas ao administrador, libera `/cofre` para ambos os usuários, ativa o suporte WebDAV (`--dav-auth`) e mantém um laço de autorrecuperação (`while true`) caso o processo seja interrompido:

```bash
while true; do copyparty --name CarbAlium -a admin:SUA_SENHA_ADMIN -a cofre:SUA_SENHA_COFRE -v /sdcard/CarbAlium:/:rwmd,admin -v /sdcard/CarbAlium/cofre:/cofre:rwmd,admin,cofre --dav-auth; sleep 2; done
```

* **Permissões aplicadas (`rwmd`):** `r` (leitura/download), `w` (escrita/upload), `m` (mover/renomear), `d` (deletar).
* **Nota sobre a tela de login:** Caso deseje que o navegador exiba a janela de senha imediatamente ao abrir a pasta principal sem precisar clicar no ícone de usuário ou adicionar `/?login` na URL, altere a montagem da raiz de `:/:rwmd,admin` para `:/geral:rwmd,admin`.

---

### 1.4. Configuração do Syncthing-Fork no Servidor

1. Instale o **Syncthing-Fork** no dispositivo servidor.
2. Abra o menu **`☰ > Configurações > Condições de execução`**:
   * **Desmarque** *Executar apenas durante o carregamento*.
   * **Desmarque** *Respeitar economia de bateria*.
3. Na aba **ESTADO**, verifique se o serviço exibe *"Syncthing está em execução"*.
4. Acesse **`☰ > Mostrar identificação`** para exibir o QR Code / ID do servidor que será usado nos dispositivos clientes.

---

## 💻 Parte 2: Configuração dos Dispositivos Clientes

### 2.1. Computadores (Windows / Linux / macOS)

1. **Instalar Tailscale:** Baixe o cliente oficial do Tailscale, faça login com a mesma conta e ative a conexão.
2. **Acesso via Navegador Web:**
   * **Painel Geral (Admin):** `http://<IP_TAILSCALE_SERVIDOR>:3923/?login`
   * **Acesso Exclusivo ao Cofre:** `http://<IP_TAILSCALE_SERVIDOR>:3923/cofre`
   * *(Certifique-se de utilizar `http://` e não `https://`).*
3. **Mapear Unidade de Rede no Windows Explorer (WebDAV):**
   * Abra o **Explorador de Arquivos > Este Computador > Mapear unidade de rede**.
   * Escolha uma letra de unidade (ex.: **`K:`**).
   * No campo **Pasta**, insira:
     ```text
     \\<IP_TAILSCALE_SERVIDOR>@3923
     ```
   * Marque **Reconectar-se na entrada** e **Conectar-se usando credenciais diferentes**.
   * Informe o usuário `admin` e a `SUA_SENHA_ADMIN` definidos no Copyparty.
4. **Sincronização de Pastas (Opcional):** Instale o **Syncthing** (ou *SyncTrayzor* no Windows), adicione o ID do servidor e configure o endereço remoto como `tcp://<IP_TAILSCALE_SERVIDOR>:22000, dynamic`.

---

### 2.2. Outros Celulares e Tablets (Android / HyperOS)

1. **Configurar Tailscale no Cliente:**
   * Instale o **Tailscale**, faça login na mesma conta e ative a VPN.
   * **Importante (Xiaomi / POCO / HyperOS):** Se o tablet ou celular cliente utilizar o recurso **Apps Duplos** (*Dual Apps*), o Android cria um perfil de trabalho oculto que pode bloquear o roteamento da VPN. Caso ocorra falha de rota, remova apps clonados não utilizados e reinicie o aparelho.
   * Faça um teste de **Ping** dentro do app Tailscale tocando no dispositivo servidor para confirmar a latência em `ms`.
2. **Acesso Rápido via Navegador (PWA):**
   * Abra o navegador do celular/tablet (em caso de erro SSL, desative *Sempre usar conexões seguras* nas configurações de privacidade do navegador).
   * Acesse `http://<IP_TAILSCALE_SERVIDOR>:3923/?login` (ou `/cofre`).
   * Toque no menu **`⋮` > Adicionar à tela inicial** para criar um atalho nativo do servidor.
3. **Configurar Syncthing-Fork no Cliente:**
   * Nas configurações do Android do cliente, defina a bateria do **Syncthing-Fork** como **Sem restrições**.
   * Dentro do app, vá em **`☰ > Configurações > Condições de execução`** e **desmarque** *Respeitar economia de bateria* e *Executar apenas durante o carregamento*.
   * Vá na aba **Dispositivos > `+`**, leia o QR Code do servidor e, no campo **Endereços**, substitua `dynamic` por:
     ```text
     tcp://<IP_TAILSCALE_SERVIDOR>:22000, dynamic
     ```
   * No servidor, aceite a solicitação de pareamento e compartilhe as pastas desejadas.

---

## 📋 Resumo de Portas e Endpoints

| Serviço | Porta | Protocolo | Endpoint / Uso |
| :--- | :---: | :---: | :--- |
| **Copyparty (Web UI)** | `3923` | HTTP | `http://<IP_TAILSCALE>:3923/?login` |
| **Copyparty (Cofre)** | `3923` | HTTP | `http://<IP_TAILSCALE>:3923/cofre` |
| **Copyparty (WebDAV)** | `3923` | HTTP/DAV | `\\<IP_TAILSCALE>@3923` (Windows Explorer) |
| **Syncthing-Fork** | `22000` | TCP/QUIC | `tcp://<IP_TAILSCALE>:22000, dynamic` |

---

## 🛠️ Solução de Problemas Comuns (Troubleshooting)

* **`ERR_SSL_PROTOCOL_ERROR` no navegador do cliente:** O navegador está redirecionando automaticamente para `https://`. Digite explicitamente `http://` ou desative a opção *Sempre usar conexões seguras* no navegador.
* **`ERR_ADDRESS_UNREACHABLE`:** Verifique se o Tailscale está conectado em ambos os dispositivos e se não há nenhum *Exit Node* ativado por engano no cliente. Em aparelhos HyperOS, verifique se há *Apps Duplos* ativos interferindo na tabela de rotas VPN.
* **Syncthing mostra "Desconectado" e a opção "Interface web" fica cinza:** O serviço em segundo plano foi pausado pela economia de bateria do Android. Desmarque *Respeitar economia de bateria* nas condições de execução do app e defina a bateria como *Sem restrições* no sistema.
* **Pasta `/cofre` abre sem solicitar senha:** Confirme se o nome da pasta física no celular (`/sdcard/CarbAlium/cofre`) possui exatamente a mesma grafia (maiúsculas/minúsculas) declarada na flag `-v` do comando do Copyparty, e teste o acesso em uma aba anônima para ignorar cookies de sessões anteriores.