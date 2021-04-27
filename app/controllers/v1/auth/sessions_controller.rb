# frozen_string_literal: true

# DeviseTokenAuth::SessionsControllerの継承クラス
class V1::Auth::SessionsController < DeviseTokenAuth::SessionsController
  include SampleData

  def create_sample
    ActiveRecord::Base.transaction do
      # 最大のuser_samples.idを取得する。
      sample_max = UserSample.all.order(id: :desc).first
      sample_id =  sample_max ? sample_max.id + 1 : 1

      # ユーザーを作成する
      user = User.create(user_data(sample_id))

      # サンプルユーザーを作成する
      user.create_user_sample(id: sample_id)

      # プロジェクトを作成する
      project = user.projects.create(project_data)

      # フォルダを作成する
      # ノートを作成する
      # タスクを作成する
      create_folder_notes_tasks(project, folder_notes_tasks_data1)
      create_folder_notes_tasks(project, folder_notes_tasks_data2)
      create_folder_notes_tasks(project, folder_notes_tasks_data3)

      # サインインする
      # サンプルユーザーのメールアドレスとパスワードでパラメータを設定（パスワードは、既定のパスワードとする）
      params.merge!(email: user.email, password: Rails.application.config.sample_user_password)
      create
    end
  end

  private

  def create_folder_notes_tasks(project, folder_notes_tasks_data)
    folder = project.folders.create(folder_notes_tasks_data[:folder])
    folder_notes_tasks_data[:notes].each do |note_task|
      note = folder.notes.create(note_task[:note].merge(project_id: project.id))

      if note_task[:has_image]
        # noteのhtmltextのSRCを置き換える
        note = replace_src(note)
        note.save
      end

      note.create_task(note_task[:task].merge(project_id: project.id)) if note_task[:task]
    end
  end

  def replace_src(note)
    image_src = create_image_src(note)

    note.htmltext = note.htmltext.sub(/SRC/, image_src)
    note
  end

  def create_image_src(note)
    # 画像取得処理を呼ぶ
    if note.update(images: image_attribute)
      image = note.images.sort_by(&:id).reverse[0]
      return url_for(image)
    end

    nil
  end

  def image_attribute
    image_encoded = Base64.encode64(IO.read('app/controllers/concerns/fixtures/notenext_greenback.png'))
    { data: "data:image/jpeg;base64,#{image_encoded}", filename: 'notenext_greenback.png' }
  end
end
