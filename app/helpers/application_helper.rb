# frozen_string_literal: true

# Helper methods for application-wide functionality including authorization checks,
# link generation, and button rendering. Provides utilities for managing resource
# access with CanCanCan integration.
module ApplicationHelper
  # Link conditionnel basé sur les permissions CanCan
  #
  # Exemples:
  #   link_to_if_authorized "Edit", edit_hike_path(@hike), action: :update, resource: Hike
  #   link_to_if_authorized "Edit", edit_hike_path(@hike), action: :update, resource: Hike, show_disabled: true
  #
  #   # Avec bloc
  #   link_to_if_authorized edit_hike_path(@hike), action: :update, resource: Hike, class: "btn" do
  #     content_tag(:i, "", class: "fas fa-pen")
  #   end
  #
  # Options:
  #   :action - L'action CanCan (:read, :update, :destroy, etc.) - Défaut: :read
  #   :resource - La ressource/classe (Hike, User, etc.) - REQUIS
  #   :show_disabled - Si true, affiche le lien en gris/désactivé si non autorisé - Défaut: false
  def link_to_if_authorized(name = nil, options = nil, html_options = nil, &block)
    # Gestion de la syntaxe avec bloc
    if block_given?
      html_options = options
      options = name
      name = nil
    end

    html_options ||= {}
    action = html_options.delete(:action) || :read
    resource = html_options.delete(:resource)
    show_disabled = html_options.delete(:show_disabled) || false

    # Vérification des permissions
    authorized = resource ? can?(action, resource) : true

    if authorized
      # Affichage normal si autorisé
      if block_given?
        link_to(options, html_options, &block)
      else
        link_to(name, options, html_options)
      end
    elsif show_disabled
      # Affichage désactivé si demandé
      disabled_html_options = html_options.dup
      existing_classes = disabled_html_options[:class].to_s
      disabled_html_options[:class] = "#{existing_classes} opacity-50 cursor-not-allowed pointer-events-none".strip
      disabled_html_options[:title] ||= "Vous n'avez pas les droits nécessaires"
      disabled_html_options.delete(:href) # Supprime le href pour vraiment désactiver

      if block_given?
        content_tag(:span, disabled_html_options, &block)
      else
        content_tag(:span, name, disabled_html_options)
      end
    else
      # N'affiche rien si non autorisé et show_disabled: false
      nil
    end
  end

  # Button conditionnel basé sur les permissions CanCan
  #
  # Exemples:
  #   button_to_if_authorized "Delete", hike_path(@hike), method: :delete, action: :destroy, resource: Hike
  #   button_to_if_authorized "Delete", hike_path(@hike), method: :delete, action: :destroy, resource: Hike, show_disabled: true
  #
  #   # Avec bloc
  #   button_to_if_authorized hike_path(@hike), method: :delete, action: :destroy, resource: Hike, class: "btn" do
  #     content_tag(:i, "", class: "fas fa-trash")
  #   end
  #
  # Options:
  #   :action - L'action CanCan (:read, :update, :destroy, etc.) - Défaut: :read
  #   :resource - La ressource/classe (Hike, User, etc.) - REQUIS
  #   :show_disabled - Si true, affiche le bouton désactivé si non autorisé - Défaut: false
  def button_to_if_authorized(name = nil, options = nil, html_options = nil, &block)
    if block_given?
      html_options = options
      options = name
      name = nil
    end

    html_options ||= {}
    action = html_options.delete(:action) || :read
    resource = html_options.delete(:resource)
    show_disabled = html_options.delete(:show_disabled) || false

    authorized = resource ? can?(action, resource) : true

    if authorized
      if block_given?
        button_to(options, html_options, &block)
      else
        button_to(name, options, html_options)
      end
    elsif show_disabled
      disabled_html_options = html_options.dup
      disabled_html_options[:disabled] = true
      existing_classes = disabled_html_options[:class].to_s
      disabled_html_options[:class] = "#{existing_classes} opacity-50 cursor-not-allowed".strip
      disabled_html_options[:title] ||= "Vous n'avez pas les droits nécessaires"

      if block_given?
        button_tag(disabled_html_options, &block)
      else
        button_tag(name, disabled_html_options)
      end
    else
      nil
    end
  end
end
