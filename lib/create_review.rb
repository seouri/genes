class CreateReview < Struct.new(:review_id)
  def perform
    review = Review.find(review_id)
    webenv, count = Rtreview::Eutils.esearch(review.search_term)
    review.search_results_count = count
    review.save!
    
    pmid = Rtreview::Eutils.efetch(webenv)
    unless pmid.size == review.search_results_count
      webenv, count = Rtreview::Eutils.esearch(review.search_term)
      pmid = Rtreview::Eutils.efetch(webenv)
      review.search_results_count = count
    end
    pg = []
    0.step(count - 1, 50000) do |start_idx|
      end_idx = start_idx + 50000
      end_idx = count - 1 if end_idx > count - 1
      pg_step = PublishedGene.where(:article_id => pmid[start_idx, end_idx]).includes(:gene)
      pg = pg.concat(pg_step)
    end
    pgg = pg.group_by(&:gene_id)
    
    pgg.sort {|a, b| pgg[b[0]].size <=> pgg[a[0]].size}.each do |g|
      rg = review.reviewed_genes.new
      rg.gene_id = g[0]
      rg.taxonomy_id = g[1][0].gene.taxonomy_id
      rg.chromosome = g[1][0].gene.chromosome
      rg.articles_count = g[1].size
      rg.specificity = g[1].size.to_f / g[1][0].gene.articles_count.to_f * 100
      rg.article_id_list = g[1].map {|a| a.article_id}
      rg.save!
    end

    review.articles_count = pg.map {|p| p.article_id}.uniq.count
    review.genes_count = pgg.keys.size
    review.built = true
    review.built_at = Time.now
    review.save!
  end
end