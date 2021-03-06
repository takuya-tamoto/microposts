class User < ApplicationRecord
  before_save { self.email.downcase! }
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  
  has_many :microposts
  #フォロー機能
  has_many :relationships
  has_many :followings, through: :relationships, source: :follow
  has_many :reverses_of_relationship, class_name: 'Relationship', foreign_key: 'follow_id'
  has_many :followers, through: :reverses_of_relationship, source: :user
  #いいね機能
  has_many :favorites, dependent: :destroy
  has_many :fav_microposts ,through: :favorites ,source: :micropost,dependent: :destroy
  
  def follow(other_user)
    unless self == other_user
      self.relationships.find_or_create_by(follow_id: other_user.id)
    end
  end

  def unfollow(other_user)
    relationship = self.relationships.find_by(follow_id: other_user.id)
    relationship.destroy if relationship
  end

  def following?(other_user)
    self.followings.include?(other_user)
  end
  
  def feed_microposts
    Micropost.where(user_id: self.following_ids + [self.id])
  end
  
  def favorite(fav_micropost)
    # お気に入りの中から、
    # ①すでにお気に入りしているユーザーがある場合、そのお気に入りインスタンスを返す
    # ②お気に入りしているユーザーがない場合、新たにお気に入りインスタンスをさ作成し、セーブする
      self.favorites.find_or_create_by(micropost_id: fav_micropost.id)
  end  
    
    # ユーザーがもつお気に入りの中から、
    # ①消そうとしているお気に入りの投稿と同じmicroposts_idをもつお気に入りインスタンスをfavoriteに代入
    # ②もし値が代入されていたら（nilじゃなければ）favorite を削除する
  def unfavorite(fav_micropost)
    favorite = self.favorites.find_by(micropost_id: fav_micropost.id)
    favorite.destroy if favorite
  end
        
  def favorite?(fav_micropost)
    self.fav_microposts.include?(fav_micropost)
  end
end