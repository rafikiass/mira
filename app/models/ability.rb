class Ability
  include Hydra::Ability

  def custom_permissions
    if current_user.registered?
      can [:create], TuftsSelfDeposit
      # Other permissions for TuftsSelfDeposit
      # (:read, :update, :destroy, :publish)
      # are already getting set by one of the upstream gems
    end

    if current_user.admin?
      can [:create, :show, :add_user, :remove_user, :index], Role
      can [:create, :read, :update, :publish, :destroy], ActiveFedora::Base
      can [:create, :read, :update, :destroy, :export], DepositType
    end
  end

  def create_permissions
    # nop - override default behavior which allows any registered user to create
  end
end

