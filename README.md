⚖️ LegalTech - Documentos Inteligentes

Uma plataforma SaaS (Software as a Service) desenvolvida para resolver a principal dor de escritórios de advocacia: o tempo excessivo gasto na redação de documentos repetitivos. O LegalTech permite que o advogado crie uma biblioteca própria de argumentações jurídicas (Tópicos) e gere petições completas de forma automatizada em poucos cliques.

✨ Funcionalidades Principais

Workspaces Modulares: Isolamento de documentos por áreas do Direito (Trabalhista, Civil, Penal, Tributário, etc.).

Gestão de Biblioteca (CRUD): Criação, edição e exclusão de Peças e Tópicos jurídicos com sincronização em tempo real na nuvem.

Document Builder Inteligente: Motor de parsing que identifica variáveis dinâmicas no texto (ex: {{NOME_CLIENTE}}, {{CPF}}) e gera formulários automaticamente para preenchimento.

Exportação Profissional: Geração de preview em Rich Text (HTML) formatado nos padrões do Judiciário (Calibri, 11pt, Títulos em Negrito). Suporte nativo para download em .doc e cópia direta para a Área de Transferência (preservando formatação no MS Word e Google Docs).

Acessibilidade e UX: Interface focada em produtividade com Dark Theme nativo e navegação acelerada por teclado (submissão de formulários via tecla Enter).

🔐 Segurança, Governança e Conformidade (LGPD)

O projeto foi construído seguindo diretrizes da família ISO 27000 e mitigando vulnerabilidades do OWASP Top 10:

Row Level Security (RLS): Banco de dados blindado no Supabase. O usuário tem acesso estritamente aos seus próprios dados por meio de validação criptográfica de token (auth.uid() = user_id), mitigando riscos de Broken Access Control.

Proteção de Rotas (Route Guarding): Redirecionamento forçado de usuários não autenticados que tentam acessar rotas protegidas (ex: /areaWorkspace).

Saneamento de Memória (Anti-vazamento): Limpeza profunda do cache de sessão e variáveis globais na memória RAM do navegador ao realizar o Log Out, garantindo isolamento total multi-tenant.

Políticas de Senha Forte: Validação rigorosa no cadastro exigindo complexidade (mínimo de 8 caracteres, maiúsculas, minúsculas, números e caracteres especiais).

🛠️ Stack Tecnológica

Frontend: Flutter Web (Dart 3.x) configurado como Single Page Application (SPA).

Backend & Auth: Supabase (PostgreSQL, Supabase Auth).

Hospedagem / Edge CDN: Netlify.

🚀 Como rodar o projeto localmente

Pré-requisitos

Flutter SDK instalado na máquina.

Google Chrome (para debug web).

VS Code ou Android Studio.

Passos

Clone este repositório:

git clone https://github.com/SEU_USUARIO/legal_flow.git


Acesse a pasta do projeto:

cd legal_flow


Instale as dependências:

flutter pub get


Execute o projeto no Chrome:

flutter run -d chrome


📦 Build e Deploy (Netlify)

Para gerar uma nova versão otimizada para produção e subir no Netlify:

Compile o projeto para Web Release:

flutter build web --release


Crie a regra de roteamento do Netlify (Evita Erro 404 ao atualizar a página):

echo "/*    /index.html   200" > build/web/_redirects


Compacte a pasta build/web e faça o upload manual do arquivo .zip no painel do Netlify (ou integre via Netlify CLI/GitHub Actions):

cd build/web && zip -r site.zip . && mv site.zip ../../ && cd ../../


👥 Equipe Desenvolvedora

Gustavo Jose Silva Farias 
