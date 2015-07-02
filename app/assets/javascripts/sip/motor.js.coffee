# vim: set expandtab tabstop=2 shiftwidth=2 fileencoding=utf-8:
# 
# Por compartir entre motores que operen sobre sip

#//= require jquery
#//= require jquery_ujs
#//= require jquery-ui/autocomplete
#//= require bootstrap-datepicker
#//= require twitter/bootstrap
#//= require turbolinks
#//= require sip/geo


# AUTOCOMPLETACIÓN

# Para autocompletación busca regitros que coincidan con lo ingresado por 
#   usuario en el campo s
#
# @param s {object} es campo texto con foco donde se busca 
# @param sel_id {string} selector de campo donde quedará identificación 
# @param fuente {mixed} arreglo, url o función que busca y retorna
#  datos de la forma label: 'l1', value: 'v1' 
#
# @return {void}
@busca_gen= (s, sel_id, fuente) ->
  s.autocomplete({
    source: fuente,
    minLength: 2,
    select: ( event, ui ) -> 
      if (ui.item) 
        $(sel_id).val(ui.item.value) if sel_id != null
        s.val(ui.item.label)
        event.stopPropagation()
        event.preventDefault()
  })
  return

# PERSONA
# Elije una persona en autocompletación
@autocompleta_persona = (label, id, id_victima, divcp) ->
  cs = id.split(";")
  id_persona = cs[0]
  pl = []
  ini = 0
  for i in [0..cs.length] by 1
     t = parseInt(cs[i])
     pl[i] = label.substring(ini, ini + t)
     ini = ini + t + 1
  # pl[1] cnom, pl[2] es cape, pl[3] es cdoc
  d = "id_victima=" + id_victima
  d += "&id_persona=" + id_persona
  a = '/personas/remplazar'
  $.ajax(url: a, data: d, dataType: "html").fail( (jqXHR, texto) ->
    alert("Error con ajax " + texto)
  ).done( (e, r) ->
    divcp.html(e)
    return
  )
  return

# Busca persona por nombre, apellido o identificación
# s es objeto con foco donde se busca persona
@busca_persona_nombre = (s) ->
  cnom = s.attr('id')
  v = $("#" + cnom).data('autocompleta')
  if (v != 1 && v != "no") 
    $("#" + cnom).data('autocompleta', 1)
    divcp = s.closest('.campos_persona')
    if (typeof divcp == 'undefined')
      alert('No se ubico .campos_persona')
      return
    idvictima = divcp.parent().find('.caso_victima_id').find('input').val()
    if (typeof idvictima == 'undefined')
      alert('No se ubico .caso_victima_id')
      return
    $("#" + cnom).autocomplete({
      source: "/personas.json",
      minLength: 2,
      select: ( event, ui ) -> 
        if (ui.item) 
          autocompleta_persona(ui.item.value, ui.item.id, idvictima, divcp)
          event.stopPropagation()
          event.preventDefault()
    })
  return

# Añade endsWith a la clase String
# http://stackoverflow.com/questions/280634/endswith-in-javascript
if (typeof String.prototype.endsWith != 'function') 
  String.prototype.endsWith = (suffix) ->
    return this.indexOf(suffix, this.length - suffix.length) != -1

# Verifica que una fecha sea válida
# De: http://stackoverflow.com/questions/8098202/javascript-detecting-valid-dates
@fecha_valida = (text) ->
  date = Date.parse(text)
  if (isNaN(date))
      return false
  comp = text.split('-')
  if (comp.length != 3)
    return false;

  y = parseInt(comp[0], 10)
  m = parseInt(comp[1], 10)
  d = parseInt(comp[2], 10)
  date = new Date(y, m - 1, d);
  return (date.getFullYear() == y && 
    date.getMonth() + 1 == m && date.getDate() == d);

# Envia con AJAX datos del formulario, junto con el botón submit.
# @param root Raiz del documento, para guardar allí variable global.
# @param f    Formulario jquery-sado
@enviarautomatico_formulario = (root, f) ->
  a = f.attr('action')
  d = f.serialize()
  d += '&commit=Enviar'
  # En ocasiones lanza 2 veces seguidas el mismo evento. 
  # Evitamos enviar lo mismo.
  if (!root.dant || root.dant != d)
    $.ajax(url: a, data: d, dataType: "script").fail( (jqXHR, texto) ->
      alert("Error con ajax " + texto)
    )
  root.dant = d 
  return

# Prepara eventos comunes al usar sip
# @param root espacio para poner variables globales
# @param puntomontaje string punto de montaje de la aplicación (por defecto /)
@sip_prepara_eventos_comunes = (root, puntomontaje) ->
  puntomontaje = '/' if typeof puntomontaje == 'undefined'

  # Formato de campos de fecha con datepicker
  $(document).on('cocoon:after-insert', (e) ->
    $('[data-behaviour~=datepicker]').datepicker({
      format: 'yyyy-mm-dd'
      autoclose: true
      todayHighlight: true
      language: 'es'
    })
  )

  jQuery ->
    $("a[rel~=popover], .has-popover").popover()
    $("a[rel~=tooltip], .has-tooltip").tooltip()

  # Al cambiar país se recalcula lista de departamentos
  $(document).on('change', 'select[id$=_id_pais]', (e) ->
    llena_departamento($(this), puntomontaje)
  )
  $(document).on('change', 'select[id$=_pais_id]', (e) ->
    llena_departamento($(this), puntomontaje)
  )

  # Al cambiar departamento se recalcula lista de municipios
  $(document).on('change', 'select[id$=_id_departamento]', (e) ->
    llena_municipio($(this), puntomontaje)
  )
  $(document).on('change', 'select[id$=_departamento_id]', (e) ->
    llena_municipio($(this), puntomontaje)
  )

  # Al cambiar municipio se recalcula lista de centros poblados
  $(document).on('change', 'select[id$=_id_municipio]', (e) ->
    llena_clase($(this), puntomontaje)
  )
  $(document).on('change', 'select[id$=_municipio_id]', (e) ->
    llena_clase($(this), puntomontaje)
  )

  $('#mundep').on('focusin', (e) ->
    busca_gen($(this), null, puntomontaje + "/mundep.json")
  )

  $(document).on('change', 'select[data-enviarautomatico]', 
    (e) -> 
      enviarautomatico_formulario(root, $(e.target.form))
  )
  $(document).on('change', 'input[data-enviarautomatico]', 
    (e) -> 
      #debugger
      # No procesa selección de fecha, pero si cuando se teclea
      #if typeof $(e.target).attr('data-behaviour') == 'undefined' || e.bubbles
      enviarautomatico_formulario(root, $(e.target.form))
  )

  return


