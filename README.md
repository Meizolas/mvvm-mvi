# MVVM vs MVI Tasks

Aplicativo Flutter Web criado para comparar duas abordagens de arquitetura, MVVM e MVI, em um gerenciador simples de tarefas.

## Requisitos

- Flutter SDK instalado
- Dart SDK compativel com `>=3.3.0 <4.0.0`
- Chrome ou outro navegador configurado para Flutter Web

## Como rodar

Instale as dependências:

```bash
flutter pub get
```

Rode o app no navegador:

```bash
flutter run -d chrome
```

## Métricas estáticas

O projeto inclui um script simples para gerar metricas comparativas entre as pastas MVVM e MVI:

```bash
dart run tool/static_metrics.dart
```

Para atualizar o arquivo CSV:

```bash
dart run tool/static_metrics.dart > static_metrics.csv
```

## Estrutura principal

- `lib/mvvm`: telas e ViewModels da versão MVVM.
- `lib/mvi`: telas, eventos, estados e BLoCs da versão MVI.
- `lib/shared`: modelos, repositório em memória, servicos e utilitarios compartilhados.
- `tool/static_metrics.dart`: script de contagem de linhas, classes e arquivos.

## Observacao

O armazenamento e feito em memória para manter o projeto simples e compativel com Flutter Web. Ao recarregar a página, os dados cadastrados são perdidos.
