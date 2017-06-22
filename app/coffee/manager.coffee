tagsHtml = [
	"A"
	"B"
	"C"
	"D"
	"E"
	"F"
	"G"
	"H"
	"I"
	"J"
	"K"
	"L"
	"M"
	"N"
	"O"
	"P"
	"Q"
	"R"
	"S"
	"T"
	"U"
	"V"
	"W"
	"X"
	"Y"
	"Z"
	"&alpha;"
]
tagsTex = [
	"A"
	"B"
	"C"
	"D"
	"E"
	"F"
	"G"
	"H"
	"I"
	"J"
	"K"
	"L"
	"M"
	"N"
	"O"
	"P"
	"Q"
	"R"
	"S"
	"T"
	"U"
	"V"
	"W"
	"X"
	"Y"
	"Z"
	"$\\Omega$"
]

class definitionObj
	tag:null
	definition:""
	tagTex:""
	tagsHtml:""
	constructor: (rank,def) ->
		@definition = def
		@tag = Number(rank)
		@tagTex = tagsTex[@tag]
		@tagHtml = tagsHtml[@tag]

class letterObj
	letter:" "
	indice:null			# indice de la lettre dans le texte, sans compter les cases noires
	indiceReel:null		# indice de la lettre dans le texte, en comptant les cases noires
	mot:null			# lien vers l'objet mot définition
	black:false			# s'agit-il d'une case noire
	inTexte:false		# Indique si la lettre est dans le texte (la lettre peut être en plus dans les mots définis)
	constructor:(params = {}) ->
		if params.letter?
			@letter = params.letter
			if @letter is " " then @black = true
		if params.indice? then @indice = params.indice
		if params.indiceReel? then @indiceReel = params.indiceReel
		if params.mot? then @mot = params.mot
		if params.inTexte? then @inTexte = params.inTexte
	set_mot: (mot) ->
		if (mot instanceof motDef) or (mot is null) then @mot = mot
		@
	texTag: ->
		switch
			when @black then "B"
			when @inTexte and (@mot isnt null) then tagsTex[@mot.tag]+@indice
			else "N"
class motDef # Classe pour un mot avec définition
	tag:null	# étiquette du mot
	liste:null	# liste des lettres
	mot:""		# string du mot
	htmlHeadTag:""
	constructor: (tag,mot,dispo) ->
		@tag = tag
		@htmlHeadTag = tagsHtml[@tag]
		@mot = mot
		@liste = []
		if dispo? then @affectation(dispo)
	affectation: (dispoLetters) ->
		# dispoLetters est la liste des lettres disponibles
		for letter in @mot
			dispo = dispoLetters[letter]
			if (typeof dispo is "undefined") or ((l = dispo.length) is 0)
				@liste.push( new letterObj { letter:letter, mot:@ } )
			else
				indice = Math.floor(l*Math.random())
				letter = dispo.splice(indice,1).pop()
				@liste.push letter.set_mot(@)
		@
	pushLetter: (letter, lettersList) ->
		switch
			when letter instanceof letterObj
				letter.set_mot @
				@liste.push letter
				@mot += letter.letter
			when $.isNumeric(letter)
				@pushLetter (it for it in lettersList when it.indice is letter)[0]
			when (typeof letter is "string") and letter.match(/\w/g)
				@mot += letter
				@liste.push( new letterObj { letter:letter, mot:@ } )
		@
	texTag: -> "H, "+(l.texTag() for l in @liste).join(", ")

class @Controller
	constructor: (params = {}) ->
		if params.texte? and (params.texte isnt "")
			@texte = params.texte
			definitions = params.definitions ? ""
			mots = params.mots ? ""
			prepared_letters = @decomposeTexte()	# tri des lettres du texte
			@ncols = params.ncols ? 20
			@definitions = ( new definitionObj(i,def) for def,i in definitions.split(";"))
			@mots = ( new motDef(i,mot,prepared_letters) for mot,i in mots.split(";") )
			@letters = @affecteLettresMots prepared_letters, @mots
			@coder()
		else if params.code isnt ""
			@decoder(params.code)
			$("#texte").val (item.letter for item in @letters).join("")
			$("#mots").val (item.mot for item in @mots).join(";")
			$("#definitions").val ( it.definition for it in @definitions).join(";")
			$("#ncols").val @ncols
		@displayTexte(@ncols)
		@displayTex()
	@init: ->
		$("form").validate {
			ignore:[]
			rules: null
			submitHandler: (event) ->
				$form = $(@currentForm)
				values = Controller.formatValues $form.serializeArray()
				new Controller {
					texte:values.texte
					mots:values.mots
					definitions:values.definitions
					ncols:Number values.ncols
					code:values.code
				}
				false
		}
		$("#decode-button").click ()->
			code = $("#code").val()
			if code isnt "" then new Controller { code:code }
	@formatValues: (arrValues)->
		out = {}
		out[it.name] = it.value for it in arrValues
		out
	decomposeTexte: ->
		# Tri les lettres du texte en regroupant par lettres
		# on obtient un objet : { A:[...lettres correspondantes], B..., black:[cases noires]}
		letters_liste= "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		letters = {}
		letters[letter] = [] for letter in letters_liste
		letters.black = []
		j=0
		for letter,i in @texte
			if letters[letter]?
				j++
				letters[letter].push( new letterObj { letter:letter, indiceReel:i, indice:j, inTexte:true } )
			else letters.black.push( new letterObj { letter:" ", indiceReel:i} )
		letters
	affecteLettresMots: (lettersList,motsList) ->
		_letters = []
		_lefts = []
		for mot in motsList
			_letters.push letter for letter in mot.liste when letter.inTexte
		for key,item of lettersList
			while (l = item.pop() )
				_letters.push l
				_lefts.push l.letter
		_letters.sort (a,b) ->	if a.indiceReel>b.indiceReel then 1 else -1
		_lefts.sort()
		console.log _lefts.join("")
		_letters
	displayTexte: (cols) ->
		lignes = []
		new_ligne = []
		for letter in @letters
			new_ligne.push letter
			if new_ligne.length >= cols
				lignes.push new_ligne
				new_ligne = []
		if new_ligne.length>0 then lignes.push new_ligne
		lignes_mots = []
		new_ligne = []
		for mot in @mots
			if (new_ligne.length + mot.liste.length + 1 > cols)
				new_ligne.push { black:true } while new_ligne.length<cols
				lignes_mots.push new_ligne
				new_ligne = []
			new_ligne.push { head:mot.htmlHeadTag }
			new_ligne.push(letter) for letter in mot.liste
		lignes_mots.push new_ligne
		$("#sujet").html Handlebars.templates.sujet { lignes:lignes, mots:lignes_mots, definitions:@definitions }
		$("#correction").html Handlebars.templates.corrige { lignes:lignes, mots:lignes_mots, definitions:@definitions }
	displayTex: () ->
		$("#tex").val Handlebars.templates.tex {
			letterTags:(l.texTag() for l in @letters).join(", ")
			motdefTags:(mot.texTag() for mot in @mots).join(", ")
			definitions: @definitions
		}

		#console.log Handlebars.templates.tex {
		#	lignes:lignes
		#	mots:lignes_mots
		#	definitions:@definitions
		#	extrait_cols_number:@ncols
		#}
	coder: ->
		_letters = []
		for letter in @letters
			switch
				when letter.black then _letters.push "#"
				when letter.mot? then _letters.push "#{letter.letter}:#{letter.mot.tag}"
				else _letters.push letter.letter
		_mots = []
		for mot in @mots
			it = { t:mot.tag, l:[]}
			for letter in mot.liste
				if letter.indice isnt null then it.l.push letter.indice
				else it.l.push letter.letter
			_mots.push it
		out = {
			n:@ncols
			l:_letters.join("|")
			m:_mots
			d:({t:it.tag, d:it.definition} for it in @definitions)
		}
		$("#code").val(JSON.stringify(out))
	decoder: (strCode)->
		code = JSON.parse strCode
		@ncols = Number(code.n) ? 20
		@letters=[]
		@mots = []
		@definitions = ( new definitionObj(it.t, it.d) for it in code.d )
		indice = 0
		for letter,i in code.l.split("|")
			switch
				when m=letter.match /// ^([A-Z]):([0-9]+)$ ///i
					indice++
					@letters.push( new letterObj { letter:m[1], tag:Number(m[2]), indice:indice, indiceReel:i, inTexte:true } )
				when m=letter.match /// ^([A-Z])$ ///i
					indice++
					@letters.push( new letterObj { letter:m[1], indiceReel:i, indice:indice, inTexte:true } )
				else
					@letters.push( new letterObj { letter:" ", indiceReel:i } )
		for itemMot in code.m
			@mots.push(nouveau_mot = new motDef(itemMot.t, ""))
			nouveau_mot.pushLetter(it,@letters) for it in itemMot.l
