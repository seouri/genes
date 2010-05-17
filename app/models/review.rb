class Review < ActiveRecord::Base
  has_many :reviewed_genes, :dependent => :delete_all, :include => [:gene => [:taxonomy, :homologene]], :order => "reviewed_genes.articles_count desc"
  validates_presence_of :search_term, :title
end