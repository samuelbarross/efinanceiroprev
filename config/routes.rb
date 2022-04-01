EFinanceiroPrev::Application.routes.draw do
    resources :usuario_empresas

    resources :empresas do
        collection do
            get :search, to: 'empresas#index'
        end
    end

    resources :movimentos do
        collection do
            get :search, to: 'movimentos#index'
            post 'processar_evento/:id', to: "movimentos#processar_evento", as: "processar_evento"
            get 'download_xml/:id', to: "movimentos#download_xml", as: "download_xml"
            get 'xml/:id', to: "movimentos#xml", as: "xml"
            post :importar_txt, to: 'movimentos#importar_txt'
            get 'download_xml_envio/:id', to: "movimentos#download_xml_envio", as: "download_xml_envio"
            get 'download_txt', to: "movimentos#download_txt", as: "download_txt"
            post 'enviar_marcados', to: 'movimentos#enviar_marcados', as: 'enviar_marcados'
            get :print_tela, to: 'movimentos#print_tela'
            get 'deleta_selecionados', to: 'movimentos#deleta_selecionados', as: 'deleta_selecionados'
        end
    end

    get 'cadastro_declarante', to: "consultas#cadastro_declarante", as: "cadastro_declarante"
    get 'consultar_informacoes_cadastrais', to: "consultas#consultar_informacoes_cadastrais", as: "consultar_informacoes_cadastrais"
    get 'informacoes_movimento', to: "consultas#informacoes_movimento", as: "informacoes_movimento"
    get 'consultar_informacoes_movimento', to: "consultas#consultar_informacoes_movimento", as: "consultar_informacoes_movimento"
    get 'lista_eFinanceira', to: "consultas#lista_eFinanceira", as: "lista_eFinanceira"
    get 'consultar_lista_eFinanceira', to: "consultas#consultar_lista_eFinanceira", as: "consultar_lista_eFinanceira"

    resources :xml_templates do
        collection { get :search, to: 'xml_templates#index' }
    end

    devise_for :users

    resources :control_users, only: [:index, :edit, :update, :show, :destroy], as: :users

    get "home/index"
    get "home/minor"
    # The priority is based upon order of creation: first created -> highest priority.
    # See how all your routes lay out with "rake routes".

    # You can have the root of your site routed with "root"
    root to: 'home#index'
    # Example of regular route:
    #   get 'products/:id' => 'catalog#view'

    # Example of named route that can be invoked with purchase_url(id: product.id)
    #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

    # Example resource route (maps HTTP verbs to controller actions automatically):
    #   resources :products

    # Example resource route with options:
    #   resources :products do
    #     member do
    #       get 'short'
    #       post 'toggle'
    #     end
    #
    #     collection do
    #       get 'sold'
    #     end
    #   end

    # Example resource route with sub-resources:
    #   resources :products do
    #     resources :comments, :sales
    #     resource :seller
    #   end

    # Example resource route with more complex sub-resources:
    #   resources :products do
    #     resources :comments
    #     resources :sales do
    #       get 'recent', on: :collection
    #     end
    #   end

    # Example resource route with concerns:
    #   concern :toggleable do
    #     post 'toggle'
    #   end
    #   resources :posts, concerns: :toggleable
    #   resources :photos, concerns: :toggleable

    # Example resource route within a namespace:
    #   namespace :admin do
    #     # Directs /admin/products/* to Admin::ProductsController
    #     # (app/controllers/admin/products_controller.rb)
    #     resources :products
    #   end
end
