def each(n): return ' Sólo puedes usar cada efecto de "%s" una vez por turno.' % n
M = '"Mermail"'
def scale(atk, what):
    return 'Equipa sólo a un monstruo ' + M + '. Gana %d ATK. Cuando se resuelva un efecto de %s activado en el lado del Campo de tu adversario, niega ese efecto y, después, manda esta carta al Cementerio.' % (atk, what)
ES = {
"Abyss-scale of the Kraken": scale(400, 'monstruo'),
"Abyss-scale of Cetus": scale(800, 'Trampa'),
"Abyss-scale of the Mizuchi": scale(800, 'Mágica'),
"Abyss-squall": 'Selecciona 3 monstruos ' + M + ' en tu Cementerio; Invoca de Modo Especial esos objetivos en Posición de Defensa boca arriba. Sus efectos quedan negados y no pueden declarar un ataque. Destrúyelos durante la End Phase.',
"Abyss-sphere": 'Invoca de Modo Especial 1 monstruo ' + M + ' de tu Deck. Sus efectos quedan negados. No puedes activar ninguna Carta Mágica. Cuando esta carta deje el Campo, destruye ese monstruo. Destruye esta carta durante la próxima End Phase de tu adversario después de su activación.',
"Abyss-steam": 'Roba tantas cartas como Tipos de Monstruo diferentes haya entre los monstruos que controlas que sean de Tipo Pez, Serpiente Marina o Aqua; además, hasta el final de tu próximo turno después de que esta carta se resuelva, no puedes Invocar de Modo Especial desde el Extra Deck, excepto monstruos de AGUA. Si uno o más monstruos de AGUA boca arriba que controlas son destruidos en batalla o por un efecto de carta, mientras esta carta está en tu Cementerio: puedes desterrar esta carta; añade a tu mano 1 monstruo ' + M + ' de tu Cementerio o de entre tus cartas desterradas.' + each("Abyss-steam"),
"Abyss-scorn": 'Selecciona 1 monstruo ' + M + ' que controles; gana 1000 ATK hasta la End Phase. Cuando esta carta Colocada sea mandada al Cementerio: selecciona 1 monstruo que controle tu adversario; manda ese objetivo al Cementerio.',
"Abyss-sting Triaina": 'Invoca de Modo Especial 1 monstruo "Atlantean" o ' + M + ' de tu mano o Cementerio y, si lo haces, equípalo con esta carta. Si el monstruo equipado fuera a ser destruido en batalla o por un efecto de carta, puedes mandar en su lugar esta carta al Cementerio. Puedes desterrar esta carta de tu Cementerio y, después, seleccionar hasta 3 de tus monstruos de Tipo Pez, Serpiente Marina y/o Aqua que estén desterrados o en tu Cementerio; barájalos en el Deck. Sólo puedes usar este efecto de "Abyss-sting Triaina" una vez por turno. Sólo puedes activar 1 "Abyss-sting Triaina" por turno.',
"Abyss-strom": 'Manda al Cementerio 1 "Umi" boca arriba que controles; manda al Cementerio todas las Cartas Mágicas y de Trampa en el Campo.',
}
