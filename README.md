# taskmaster-architecture — N 層からオニオンへ（002 / 003）

このブランチは、記事 002（3 層アーキテクチャ）と記事 003（N 層からオニオンへの移行）の状態をタグで残しています。
004 以降の Gradle マルチプロジェクト版は `main` ブランチ（タグ `article-004`）にあります。

| タグ | 状態 |
|---|---|
| `article-002` | 002 の N 層（`controller` / `service` / `repository` / `entity` / `dto`）|
| `article-003-model` | 002 のパッケージのまま、`Task` にルールを持たせた状態（`TaskStatus`・`dueDate`・`complete()` / `startProgress()`）|
| `article-003` | オニオンの 4 パッケージ（`domain` / `application` / `infrastructure` / `presentation`）へ移した状態 |

## 動作環境

| 項目 | 版 |
|---|---|
| Java | 25 |
| Spring Boot | 4.1.1 |
| Gradle | Wrapper で固定（`gradle/wrapper/gradle-wrapper.properties`）|
| Docker | アプリの起動（`./gradlew bootRun`）に必要（PostgreSQL 17 を `compose.yml` で起動）|

## テストの実行

```bash
./gradlew test
```

テストは Spring を起動しないため、Docker は要りません。

## 差分を見る

```bash
git diff --stat article-002 article-003
```

## 記事の掲載コードとの違い

- 002 の記事に掲載していない `settings.gradle.kts`・`TaskmasterApplication.java`・Gradle Wrapper を足しています
- Spring Boot は記事の 4.0.5 ではなく 4.1.1 です
- `article-003` の `domain` と `application` の `TaskService` / `TaskResponse` は、`article-004` と同じコードです。`TaskRequest` の入力検証と `TaskNotFoundException` のメッセージは 002 のまま残しています
