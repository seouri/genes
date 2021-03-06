class ReviewedGene < ActiveRecord::Base
  belongs_to :review
  belongs_to :gene
  belongs_to :taxonomy
  serialize :article_id_list

  scope :homologs, lambda {|review, gene| where(:review_id => review.id).where(:gene_id => gene.homologs.compact.map {|h| h.id}).includes(:gene).order("articles_count desc") }
end
