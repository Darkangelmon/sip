# encoding: UTF-8

module Sip
  module Concerns
    module Controllers
      module ActoressocialesController
        extend ActiveSupport::Concern

        included do

          before_action :set_actorsocial, only: [:show, :edit, :update, :destroy]
          load_and_authorize_resource class: Sip::Actorsocial


          def clase
            "Sip::Actorsocial"
          end

          def genclase
            return 'M'
          end

          def atributos_index
            [ :id, 
              :grupoper_id,
              { :sectoractor_ids => [] },
              :web,
              :telefono, 
              :fax,
              :pais,
              :direccion,
              :habilitado
            ]
          end

          def atributos_show
            atributos_index - [:habilitado] + 
              [:fechadeshabilitacion_localizada]
          end

          def atributos_form
            a = atributos_show - [:id]
            a[a.index(:grupoper_id)] = :grupoper
            return a
          end

          def index(c = nil)
            if c == nil
              c = Sip::Actorsocial.all
            end
            super(c)
          end

          def set_actorsocial
            @actorsocial = Sip::Actorsocial.find(params[:id])
            @registro = @actorsocial
          end

          def actorsocial_params
            params.require(:actorsocial).permit(
              atributos_form - [:grupoper] +
              [ :pais_id,
                :grupoper_attributes => [
                :id,
                :nombre,
                :anotaciones ]
              ]) 
          end

        end #included

      end
    end
  end
end

