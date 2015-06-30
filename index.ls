root = exports ? this

J = $.jade

root.lang = 'en'

root.synthesize_word_queue = []

stop_synthesis = ->
  root.synthesize_word_queue = []
  get-video-tag()[0].pause()

synthesize_word_for_tag = (word, video_tag) ->
  console.log 'synthesize_word_for_tag'
  console.log word
  console.log video_tag
  video_tag.attr 'src', 'http://speechsynth.herokuapp.com/speechsynth?' + $.param({lang: root.lang, word})
  video_tag[0].currentTime = 0
  video_tag[0].play()

get-video-tag = ->
  video_tag = $('video')
  if video_tag.length == 0
    video_tag = J('video').css({display: 'none'}).on 'ended', ->
      console.log 'video ended!'
      synthesize_next_word(video_tag)
    video_tag.appendTo('body')
  return video_tag

synthesize_next_word = (video_tag) ->
  video_tag = video_tag ? get-video-tag()
  $('.bolded').removeClass 'bolded'
  if root.synthesize_word_queue.length > 0
    [next_word, next_tag] = root.synthesize_word_queue.shift(0)
    next_tag.addClass 'bolded'
    synthesize_word_for_tag next_word, video_tag
  #$('.bolded').not(video_tag).removeClass 'bolded'

synthesize_word_and_highlight = (word, tag) ->
  video_tag = get-video-tag()
  root.synthesize_word_queue.push [word, tag]
  if video_tag[0].paused
    synthesize_next_word(video_tag)

synthesize_word = (word) ->
  synthesize_word_and_highlight word, $()

export find_next_break = (text, start) ->
  earliest_next_break = text.length
  for letter in <[ ? ! . ]>
    new_idx = text.indexOf letter, start
    if new_idx == -1
      continue
    if new_idx < earliest_next_break
      earliest_next_break = new_idx
  return earliest_next_break

export getIPA = (word) ->
  ipa = ipadict_en[word.trim().toLowerCase()]
  if not ipa?
    if word.indexOf('-') != -1
      return [getIPA(x) for x in word.split('-')].join('-')
    return word
  return ipa

export split_sentences = (text) ->
  output = []
  idx = 0
  while true
    next_break = find_next_break text, idx
    if next_break == text.length
      break
    output.push text[idx to next_break].join('')
    idx = next_break + 1
  return output

export split_words = (text) ->
  output = []
  curword = []
  end_word = ->
    if curword.length > 0
      output.push {type: 'word', text: curword.join('')}
      curword := []
  for c in text
    if [' ', ',', '.', '?', '!'].indexOf(c) != -1
      end_word()
      output.push {type: 'silent', text: c}
    else
      curword.push c
  end_word()
  return output

getlevel = ->
  return $('#level_selector_input').val().trim()



add-word = (word_text, sentence_span) ->
  word_span = J('span.word')
  word_span.text getIPA(word_text)
  word_span.data({text: word_text})
  word_span.click ->
    if getlevel() == 'word'
      stop_synthesis()
      console.log word_text
      synthesize_word_and_highlight word_text, word_span
  word_span.appendTo sentence_span

add-sentence = (sentence_text, container) ->
  sentence_span = J('span')
  #sentence_span.data 'level', 'sentence'
  #sentence_span.data 'level', 'word'
  #for word in split_words()
  for {type, text} in split_words(sentence_text)
    if type == 'silent'
      J('span').text(text).appendTo sentence_span
    else
      add-word text, sentence_span
  #sentence_span.click ->
  #  synthesize_word sentence_text
  sentence_span.click ->
    $('.highlighted').removeClass 'highlighted'
    sentence_span.addClass 'highlighted'
    if getlevel() == 'sentence'
      stop_synthesis()
      for x in sentence_span.find('span.word')
        synthesize_word_and_highlight $(x).data('text'), $(x)
      #word_text = $(x).data('text')
      #synthesize_word word_text
  sentence_span.appendTo container
  /*
  span.text(text).click ->
    synthesize_word text
    span.css 'background-color', 'yellow'
    #joketext = $(this).data('joketext')
  */

add-joke = (joketext) ->
  container = J('span')
  for sentence in split_sentences(joketext)
    add-sentence sentence, container
  container.appendTo '#contents'
  J('br').appendTo '#contents'

export getUrlParameters = ->
  url = window.location.href
  hash = url.lastIndexOf('#')
  if hash != -1
    url = url.slice(0, hash)
  map = {}
  parts = url.replace(/[?&]+([^=&]+)=([^&]*)/gi, (m,key,value) ->
    #map[key] = decodeURI(value).split('+').join(' ').split('%2C').join(',') # for whatever reason this seems necessary?
    map[key] = decodeURIComponent(value).split('+').join(' ') # for whatever reason this seems necessary?
  )
  return map

$(document).ready ->
  dictfile = '/ipadict_en.json'
  {condition} = getUrlParameters()
  if condition?
    if condition == '0'
      dictfile = '/ipadict_en.json'
    if condition == '1'
      dictfile = '/ipadict_en_obf1.json'
    if condition == '2'
      dictfile = '/ipadict_en_obf2.json'
  $.getJSON dictfile, (data) ->
    root.ipadict_en = data
    have_ipadict()

have_ipadict = ->
  level_selector_div = J('div#level_selector_div')
  level_selector_input = J('input(type="text" id="level_selector_input" value="sentence" list="level_options")')
  level_selector_options = J('datalist(id="level_options")')
  level_selector_options.append J('option').text('sentence')
  level_selector_options.append J('option').text('word')
  level_selector_div.append [J('span').text('Speech synthesis level:'), level_selector_input, level_selector_options]
  level_selector_div.appendTo '#contents'
  $.get '/jokes_list.txt', (data) ->
    #console.log JSON.stringify data
    for joke in data.split('\r\n').join('\n').split('\n\n')
      add-joke joke
  #$('#contents').text 'foobar'
