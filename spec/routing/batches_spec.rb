require 'spec_helper'

describe 'Batch routes:' do
  it 'routes to create' do
    expect(post: 'batch/template_updates').to route_to(
      controller: 'batch/template_updates',
      action: 'create'
    )
  end

  it 'routes to index' do
    expect(get: 'batches').to route_to(
      controller: 'batches',
      action: 'index'
    )
  end

  it 'routes to show' do
    expect(get: 'batch/template_updates/1').to route_to(
      controller: 'batch/template_updates',
      action: 'show',
      id: '1'
    )
  end

  it 'routes to template_import#new' do
    expect(get: 'batch/template_imports/new').to route_to(
      controller: 'batch/template_imports',
      action: 'new'
    )
  end

  it 'routes to xml_import#new' do
    expect(get: 'batch/xml_imports/new').to route_to(
      controller: 'batch/xml_imports',
      action: 'new'
    )
  end

  it 'routes to edit' do
    expect(get: 'batch/xml_imports/1/edit').to route_to(
      controller: 'batch/xml_imports',
      action: 'edit',
      id: '1'
    )
  end

  it 'routes to update' do
    expect(patch: 'batch/xml_imports/1').to route_to(
      controller: 'batch/xml_imports',
      action: 'update',
      id: '1'
    )
  end
end
