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
./gradlew :domain:test :application:test
```

`infrastructure` と `presentation` は、現時点ではディレクトリだけを用意しています。

## 測定結果

`results/` に記事で使う測定の生ログを置いています。
