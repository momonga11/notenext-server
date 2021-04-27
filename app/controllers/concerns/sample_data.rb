# frozen_string_literal: true

# サンプルデータを定義するモジュール
module SampleData
  def user_data(number)
    email = "sample-user#{number}@notenext-app.com"

    {
      name: "サンプルユーザー#{number}",
      email: email,
      password: Rails.application.config.sample_user_password,
      provider: 'email',
      uid: email,
      confirmed_at: Time.now
    }
  end

  def project_data
    {
      name: 'NN(仮) アプリ開発',
      description: 'タスク管理ツール NN(仮)の全体管理。'
    }
  end

  def folder_notes_tasks_data1
    {
      folder: {
        name: '企画定例会',
        description: '企画定例会の議事録をまとめるフォルダ。'
      },
      notes: [
        {
          note: {
            created_at: '2021/4/1 12:00:00',
            updated_at: '2021/4/1 12:58:00',
            title: '2021/4/1 キックオフ打ち合わせ',
            text: <<~TEXT,
              コンセプト案

              メモ帳のような使い方でタスクの管理をできるようにする

              プロジェクト→フォルダ→ファイル、のような階層構造

              想定顧客は、個人、あるいは比較的小規模の企業。

              類似製品との比較

              製品名	特徴	金額
              Juro	かんばん形式でタスク管理をする。	1ユーザー無料、5ユーザー 月額50万
              BoA	エンジニア向けのタスク管理ツール。
              プロジェクト単位にカスタム項目を設定可能。3ユーザー 200万、サポート費用年40万。
            TEXT

            htmltext: <<~TEXT
              <h2>コンセプト案</h2>
              <ul>
              <li><strong>メモ帳のような</strong>使い方でタスクの管理をできるようにする</li>
              <li>プロジェクト→フォルダ→ファイル、のような階層構造</li>
              <li>想定顧客は、個人、あるいは比較的小規模の企業。</li> </ul>
              <p><br data-tomark-pass=""></p>
              <h3>類似製品との比較</h3>
              <table>
              <thead>
              <tr>
              <th>製品名</th>
              <th>特徴</th>
              <th>金額</th>
              </tr>
              </thead>
              <tbody>
              <tr>
              <td>Juro</td>
              <td>かんばん形式でタスク管理をする。</td>
              <td>1ユーザー無料、5ユーザー 月額50万</td>
              </tr>
              <tr>
              <td>BoA</td>
              <td>エンジニア向けのタスク管理ツール。<br data-tomark-pass="">プロジェクト単位にカスタム項目を設定可能。</td>
              <td>3ユーザー 200万、サポート費用年40万。</td>
              </tr>
              </tbody>
              </table>
            TEXT

          },
          has_image: false
        },
        {
          note: {
            created_at: '2021/4/8 12:01:00',
            updated_at: '2021/4/9 10:31:00',
            title: '2021/4/8 第2回打ち合わせ',
            text: <<~TEXT,
              質問事項まとめ

              ・コミュニケーションツールとしての機能がないが、不要か。

                  →初回リリースでは作らないが、ユーザーの要望次第では２次フェーズ以降で開発する。

              ・ロゴのイメージは作成中か。

              　→デザイナーに依頼中。来週には出せる。

              ・人員計画の草案はあるか？　現在AT案件が開始間近、CK案件が再来月終了予定。CK案件の人員をこちらに回すか。

              　→CK案件のPMは井上さんのため、確認しておく。


              来週までの課題

              ロゴイメージについて共有

              人員計画について、CK案件について井上さんに確認する
            TEXT

            htmltext: <<~TEXT
              <h2>質問事項まとめ</h2>
              <p>・コミュニケーションツールとしての機能がないが、不要か。<br>
              &nbsp;&nbsp;&nbsp;&nbsp;→初回リリースでは作らないが、ユーザーの要望次第では２次フェーズ以降で開発する。<br>
              ・ロゴのイメージは作成中か。<br> 　→デザイナーに依頼中。来週には出せる。<br>
              ・人員計画の草案はあるか？　現在AT案件が開始間近、CK案件が再来月終了予定。CK案件の人員をこちらに回すか。<br>
              　→CK案件のPMは井上さんのため、確認しておく。</p> <p><br data-tomark-pass=""></p>
              <h4>来週までの課題</h4>
              <ul>
              <li class="task-list-item checked" data-te-task="">ロゴイメージについて共有</li>
              <li class="task-list-item checked" data-te-task="">人員計画について、CK案件について井上さんに確認する</li>
              </ul>
            TEXT

          },
          task: { date_to: '2021-04-15', completed: true },
          has_image: false
        },
        {
          note: {
            created_at: '2021/4/15 11:54:00',
            updated_at: '2021/4/15 13:10:00',
            title: '2021/4/15 第3回打ち合わせ',
            text: <<~TEXT,
              報告まとめ

              ロゴイメージは以下の通り


              CK案件PM井上さんに確認したところ、３人空きが出るとのこと。

              以下の体制で進める。

              PM：伊藤

              ・4月〜6月：３名(+1名新規採用あり)

              ・7月〜　  ：CK案件から３名追加


              質問事項まとめ

              ・営業部との調整はどうなっているのか？

              →近藤さんが今週まで出張のため、来週頭に打ち合わせ予定。

              ・プロトタイプ完成が9月では遅い。7月中までがベストではないか。

              →プロトタイプの機能を減らすか。


              来週までの課題

              営業部との打ち合わせ結果の共有

              プロトタイプについて、各自持ち帰って検討
            TEXT

            htmltext: <<~TEXT
              <h2>報告まとめ</h2>
              <h4>ロゴイメージは以下の通り</h4>
              <p><img src="SRC" alt="image"><br> <br data-tomark-pass=""></p>
              <h4>CK案件PM井上さんに確認したところ、３人空きが出るとのこと。</h4>
              <p>以下の体制で進める。<br> PM：伊藤<br> ・4月〜6月：３名(+1名新規採用あり)<br> ・7月〜　&nbsp; ：CK案件から３名追加<br> <br data-tomark-pass=""></p>
              <h2>質問事項まとめ</h2>
              <p>営業部との調整はどうなっているのか？<br>
              →近藤さんが今週まで出張のため、来週頭に打ち合わせ予定。<br>
              ・プロトタイプ完成が9月では遅い。7月中までがベストではないかか<br>
              →プロトタイプの機能を減らすか。<br> <br data-tomark-pass=""></p>
              <h4>来週までの課題</h4> <ul> <li class="task-list-item" data-te-task="">営業部との打ち合わせ結果の共有</li>
              <li class="task-list-item" data-te-task="">プロトタイプについて、各自持ち帰って検討</li>
              </ul>
            TEXT

          },
          task: { date_to: '2021-04-22', completed: false },
          has_image: true
        }
      ]
    }
  end

  def folder_notes_tasks_data2
    {
      folder: {
        name: '開発進捗',
        description: '開発の進捗について、打ち合わせメモを記録する。'
      },
      notes: [
        {
          note: {
            created_at: '2021/4/2 10:10:00',
            updated_at: '2021/4/2 11:11:00',
            title: 'アプリケーション形態検討',
            text: <<~TEXT,
              WEBアプリケーションか、ネイティブアプリか。

              アプリで細かいタスク管理をしづらい。メモ帳としての機能はネイティブアプリでも有用。

              タスク期限のプッシュ通知を作るのであれば、ネイティブアプリの方がいい。

              PWAなら一石二鳥？


              PWAについて調査・検討
            TEXT

            htmltext: <<~TEXT
              <h5>WEBアプリケーションか、ネイティブアプリか。</h5>
              <ul>
              <li>アプリで細かいタスク管理をしづらい。メモ帳としての機能はネイティブアプリでも有用。</li>
              <li>タスク期限のプッシュ通知を作るのであれば、ネイティブアプリの方がいい。</li>
              <li><span class="colour" style="color: rgb(77, 81, 86);" data-tomark-pass="">PWAなら一石二鳥？</span></li>
              </ul>
              <p><br data-tomark-pass=""></p>
              <ul>
              <li class="task-list-item" data-te-task=""><strong>PWAについて調査・検討</strong></li>
              </ul>
              <p><span class="colour" style="color: rgb(77, 81, 86);" data-tomark-pass=""></span></p>
            TEXT

          },
          task: { date_to: '2021/04/14', completed: false },
          has_image: false
        },
        {
          note: {
            created_at: '2021/4/5 16:43:00',
            updated_at: '2021/4/6 16:11:00',
            title: '言語検討',
            text: <<~TEXT,
              候補

              Ruby

              メンバー習熟度が最も高く、他アプリでの実績あり。


              Python

              将来的に機械学習・統計を活用するのであれば、積極採用していい。

              メンバー習熟度も低くはないが、PLの南が未経験のため厳しいか。


              Go

              人気が高まってきている言語。技術レベルの高いエンジニアの参画が期待できるか？

              社内のほとんどのメンバーが未経験のため、学習コストがかなり高い。
            TEXT

            htmltext: <<~TEXT
              <h2>候補</h2>
              <h4>Ruby</h4>
              <ul>
              <li>メンバー習熟度が最も高く、他アプリでの実績あり。</li>
              </ul>
              <p><br data-tomark-pass=""></p>
              <h4>Python</h4>
              <ul>
              <li>将来的に機械学習・統計を活用するのであれば、積極採用していい。</li>
              <li>メンバー習熟度も低くはないが、PLの南が未経験のため厳しいか。</li>
              </ul>
              <p><br data-tomark-pass=""></p>
              <h4>Go</h4>
              <ul>
              <li>人気が高まってきている言語。技術レベルの高いエンジニアの参画が期待できるか？</li>
              <li>社内のほとんどのメンバーが未経験のため、学習コストがかなり高い。</li>
              </ul>
              <p><br data-tomark-pass=""><br>
              <br data-tomark-pass=""></p>
            TEXT

          },
          task: { date_to: '2021-04-21', completed: false },
          has_image: false
        }
      ]
    }
  end

  def folder_notes_tasks_data3
    {
      folder: {
        name: '今週の感想',
        description: 'メンバーの今週の感想を記載するフォルダ'
      },
      notes: [
        {
          note: {
            created_at: '2021/4/20 16:01:00',
            updated_at: '2021/4/20 16:26:00',
            title: '2021/4/20',
            text: <<~TEXT,
              森山
              在宅勤務に慣れすぎて、久しぶりの出社が疲れた。満員電車キツい・・・

              山田
              オンライン飲み会を初めてやってみた。悪くないがツマミがなくなる。


              P○5が全く買えない。どこに売っているのか。


              案件について。進捗は予定通りだが、正直終わりが見えない。フェーズを分けて、どこかで区切りをつけたい。


              田中
              社内勉強会を開催してみた。↑二人しか参加してくれなくて悲しかった。
            TEXT

            htmltext: <<~TEXT
              <p>森山</p>
              <ul>
              <li>在宅勤務に慣れすぎて、久しぶりの出社が疲れた。<del>満員電車キツい・・・</del></li>
              </ul>
              <hr>
              <p>山田</p>
              <ul>
              <li>オンライン飲み会を初めてやってみた。悪くないがツマミがなくなる。</li>
              <li>P○5が全く買えない。どこに売っているのか。</li>
              <li>案件について。進捗は予定通りだが、正直終わりが見えない。フェーズを分けて、どこかで区切りをつけたい。</li>
              </ul>
              <p><br data-tomark-pass=""></p>
              <hr>
              <p>田中</p>
              <ul>
              <li>社内勉強会を開催してみた。↑二人しか参加してくれなくて悲しかった。</li>
              </ul>
            TEXT

          },
          has_image: false
        },
        {
          note: {
            created_at: '2021/4/27 16:03:00',
            updated_at: '2021/4/27 16:28:00',
            title: '2021/4/27',
            text: <<~TEXT,
              森山


              出社すると運動になるのがいい。慣れてきた。


              フロントエンドがわからなすぎてヤバイ。


              山田

              P○5が欲しかったが、そもそも欲しいソフトがないことに気がついた。

              案件のゴールについて、PMと話してみた。話してみると意外と話しやすく、なんとなく道筋が見えてきた。


              田中  社内勉強会の内容をメジャーな技術に変えてみたら参加者が急に増えた。やる気出た。


              中井 今日からよろしくお願いします！！
            TEXT

            htmltext: <<~TEXT
              <p>森山</p>
              <ul>
              <li>出社すると運動になるのがいい。慣れてきた。</li>
              <li>フロントエンドがわからなすぎてヤバイ。</li>
              </ul>
              <hr>
              <p>山田</p>
              <ul>
              <li>P○5が欲しかったが、そもそも欲しいソフトがないことに気がついた。</li>
              <li>案件のゴールについて、PMと話してみた。話してみると意外と話しやすく、なんとなく道筋が見えてきた。</li>
              </ul>
              <hr>
              <p>田中</p>
              <ul>
              <li>社内勉強会の内容をメジャーな技術に変えてみたら参加者が急に増えた。やる気出た。</li>
              </ul>
              <p><br data-tomark-pass=""></p>
              <hr>
              <p>中井</p>
              <ul>
              <li>今日からよろしくお願いします！！</li>
              </ul>
            TEXT

          },
          has_image: false
        }
      ]
    }
  end
end
