# flutter3-and-supabase-study

## このリポジトリについて
- Flutter3とSupabaseの勉強用リポジトリです
  - Supabaseの認証機能を用いた認証が行えます
    - このアプリ内からのサインアップは作っていません
    - パスワード認証の他にGitHubとGoogleアカウントを利用したソーシャルログインも行えます（Supabase側のAuthentication -> Auth Providersの設定が必要）
  - ログイン後の画面でタスクに関するCRUDを行えます
    - 登録後のタスクはスイッチによって完了/未完了の更新を行えます
    - タスクの並びについて長押しでタスクを掴んで任意の位置に入れ替えることができます
- 環境構築に[fvm(v3)](https://github.com/leoafarias/fvm/releases/tag/3.0.0-beta.5)を使っています

## Supabaseのtasksテーブル
以下のような定義となっています
```sql
create table
  public.tasks (
    id bigint generated by default as identity,
    created_at timestamp with time zone not null default now(),
    title text null,
    completed boolean not null default false,
    "user" uuid not null default auth.uid (),
    sort_num bigint generated by default as identity,
    constraint tasks_pkey primary key (id)
  ) tablespace pg_default;
```

RLSは以下のようになっています

| roles    | cmd    | qual                  | with_check            |
| -------- | ------ | --------------------- | --------------------- |
| {public} | INSERT |                       | (auth.uid() = "user") |
| {public} | SELECT | (auth.uid() = "user") |                       |
| {public} | UPDATE | (auth.uid() = "user") |                       |
| {public} | DELETE | (auth.uid() = "user") |                       |

- ログイン中のユーザーIDとuserカラムの値が一致するもののみINSERT、SELECT、UPDATE、DELETE可能というRLS（のはず）
- `SELECT roles, cmd, qual, with_check FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tasks';`で確認
