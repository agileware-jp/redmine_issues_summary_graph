match 'issues_summary_graph/:project_id/:action(.:format)', :controller => 'issues_summary_graph', :via => [:get, :post]

resources :issues_summary_graph, only: [] do
  collection do
    get :replace_options
  end
end
