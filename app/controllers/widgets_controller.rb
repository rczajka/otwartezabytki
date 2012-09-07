# encoding: utf-8
class WidgetsController < ApplicationController
  layout :resolve_widget_layout, :only => :show

  def resolve_widget_layout
    if request.xhr?
      'ajax'
    else
      'widget'
    end
  end

  before_filter :authenticate_user!, :except => [:show]

  expose(:widget_templates) { WidgetTemplate.scoped }
  expose(:widget_template)

  expose(:widgets) { current_user.widgets }
  expose(:widget) do
    the_widget = if params[:id].present?
      if params[:id].match(/^\d+$/)
        Widget.find(params[:id])
      else
        Widget.find_by_uid!(params[:id])
      end
    else
      w = widgets.build
      w.widget_template = WidgetTemplate.find(params[:widget_template_id]) if params[:widget_template_id]
      w
    end

    the_widget.attributes = params[:widget] unless request.get?
    the_widget
  end

  expose(:widget_search) do
    params[:search] ||= { :location => 'country:pl' }
    params[:search]["widget"] = "1"
    Search.new(params[:search])
  end

  expose(:relics) do
    widget_search.load = true
    widget_search.perform
  end

  def show
    if respond_to?(widget.widget_template.partial_name)
      send(widget.widget_template.partial_name)
    end
  end

  def create
    if widget.save
      redirect_to edit_widget_path(widget.id)
    else
      flash[:error] = "Nie udało się stworzyć widgeta. Zgłoś błąd administracji."
      redirect_to widgets_path
    end
  end

  def update
    if widget.save
      redirect_to edit_widget_path(widget.id), :notice => "Widget został zaktualizowany"
    else
      flash[:error] = "Nie udało się zaktualizować widgeta. Popraw błędy poniżej."
      render :edit
    end
  end

  def map_search

  end
end
