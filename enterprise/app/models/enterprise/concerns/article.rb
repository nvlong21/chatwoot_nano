module Enterprise::Concerns::Article
  extend ActiveSupport::Concern

  included do
    after_save :add_article_embedding, if: -> { saved_change_to_title? || saved_change_to_description? || saved_change_to_content? }

    def self.add_article_embedding_association
      has_many :article_embeddings, dependent: :destroy_async
    end

    add_article_embedding_association
  end

  def add_article_embedding
    return unless account.feature_enabled?('help_center_embedding_search')

    Portal::ArticleIndexingJob.perform_later(self)
  end
end
