# taskmaster-architecture

Spring Boot のアーキテクチャ設計（N 層 → オニオン）を学ぶためのサンプル `taskmaster`（タスク管理アプリ）です。
Gradle マルチプロジェクトで、ドメイン層・アプリケーション層・インフラ層・プレゼンテーション層を分けて構成します。

## 動作環境

| 項目 | 版 |
|---|---|
| Java | 25 |
| Gradle | Wrapper で固定（`gradle/wrapper/gradle-wrapper.properties`）|

## テストの実行

```bash
./gradlew test
```

`presentation` の統合テストは Testcontainers で PostgreSQL のコンテナを起動するため、Docker が要ります。

## アプリの起動

```bash
./gradlew :presentation:bootRun
```

Spring Boot の Docker Compose 連携が、ルートの `compose.yaml` から PostgreSQL を起動します。

## Spring Modulith のサンプル（`modulith/`）

`modulith/` は、オニオンの taskmaster とは別の独立したビルドです。task / notification / report の 3 つのモジュールで、Spring Modulith の依存の検証とモジュール間のイベントを試せます。

```bash
./gradlew -p modulith test
```

テストは Testcontainers で PostgreSQL のコンテナを起動するため、Docker が要ります。

## 測定結果

`results/` に記事で使う測定の生ログを置いています。
