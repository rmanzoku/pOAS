# pOAS Token Project

OASチェーン上で動作する担保付きポイントトークン（pOAS）の実装です。

## 概要

pOASは以下の特徴を持つERC20トークンです：

- OASを担保として保持
- 承認された支払い先（PAYMENT_ROLE）への送金時にOASに変換
- 管理者による担保の追加・引き出し機能
- MINTERによる新規発行機能

## セットアップ

```bash
# 依存関係のインストール
npm install

# 環境変数の設定
cp .env.example .env
# .envファイルを編集して必要な値を設定
```

## 開発コマンド

```bash
# コントラクトのコンパイル
npm run compile

# テストの実行
npm run test

# デプロイ
npm run deploy
```

## 重要な注意点

### 担保率について

- pOASの価値はコントラクトが保持するOASによって裏付けられています
- 担保率 = コントラクト内のOAS残高 / pOASの総供給量
- 担保率が1を下回ると、支払い（PAYMENT_ROLEへの送金）が失敗します
- オフチェーンで`getCollateralRatio()`を監視することを推奨します

### セキュリティ

- `ADMIN_ROLE`: 担保の管理を行えます
- `MINTER_ROLE`: 新規トークンを発行できます
- `PAYMENT_ROLE`: トークンの支払い先として指定できます

### 利用上の制限

- 一般ユーザー間の転送はできません
- 支払いは`PAYMENT_ROLE`を持つアドレスに対してのみ可能です
- 支払い時に担保が不足している場合は失敗します

## コントラクトの利用方法

### 管理者向け

```solidity
// 担保の追加
poas.depositCollateral{value: amount}();

// 担保の引き出し（担保率1以上が必要）
poas.withdrawCollateral(amount);

// ロールの付与
poas.grantRole(PAYMENT_ROLE, address);
```

### 一般ユーザー向け

```solidity
// 支払い先への送金（自動的にOASに変換）
poas.transfer(paymentAddress, amount);
```

### ClaimSampleの利用

```solidity
// 一度だけ100 pOASを受け取れます
claimSample.claim();
```
