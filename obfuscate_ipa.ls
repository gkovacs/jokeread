require! {
  fs
  'array-shuffle'
}

ipadict_en = fs.readFileSync 'ipadict_en.json', 'utf8' |> JSON.parse

letter_dict = {}
for k,v of ipadict_en
  for letter in v
    letter_dict[letter] = true

letters = Object.keys letter_dict
#target_letters = arrayShuffle(letters)
target_letters = [\ა to \ჶ] # georgian alphabet

letter_mapping = {}
for i in [0 til letters.length]
  letter_mapping[letters[i]] = target_letters[i]

output = {}
for k,v of ipadict_en
  target_word = [letter_mapping[letter] for letter in v].join('')
  output[k] = target_word

fs.writeFileSync 'ipadict_en_obf2.json', JSON.stringify output
