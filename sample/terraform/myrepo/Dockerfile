# 公式のPythonベースイメージから始めます
FROM python:3.9

# 現在の作業ディレクトリを /code に設定します
# ここに requirements.txt ファイルと app ディレクトリを置きます。
WORKDIR /code

# 要件が書かれたファイルを /code ディレクトリにコピーします
# 残りのコードではなく、最初に必要なファイルだけをコピーしてください。
COPY ./requirements.txt /code/requirements.txt

# 要件ファイルにあるパッケージの依存関係をインストールします --no-cache-dir オプションはダウンロードしたパッケージをローカルに保存しないように pip に指示します。
# これは、同じパッケージをインストールするために pip を再度実行する場合にのみ有効ですが、コンテナで作業する場合はそうではないです。
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# /appディレクトリを/code` ディレクトリの中にコピーする。
COPY ./app /code/app

# uvicornサーバーを実行するためのコマンドを設定します
# CMD は文字列のリストを取り、それぞれの文字列はスペースで区切られたコマンドラインに入力するものです。
# このコマンドは 現在の作業ディレクトリから実行され、上記の WORKDIR /code にて設定した /code ディレクトリと同じです。
# そのためプログラムは /code で開始しその中にあなたのコードがある ./app ディレクトリがあるので、Uvicorn は app.main から app を参照し、インポート することができます。
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]