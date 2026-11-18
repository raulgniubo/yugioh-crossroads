def once(n): return ' Sólo puedes usar este efecto de "%s" una vez por turno.' % n
def act1(n): return ' Sólo puedes activar 1 "%s" por turno.' % n
F = '"Fortune Lady"'
def base(x): return 'El ATK/DEF de esta carta pasan a ser su Nivel x %d. Una vez por turno, durante tu Standby Phase: aumenta el Nivel de esta carta en 1 (máx. 12).' % x
ES = {
"Fortune Lady Calling": 'Si controlas un monstruo ' + F + ': Invoca de Modo Especial 1 monstruo ' + F + ' de tu Deck con un nombre diferente al de las cartas que controlas; además, durante el resto de este turno después de que esta carta se resuelva, no puedes Invocar de Modo Especial monstruos desde el Extra Deck, excepto Monstruos de Sincronía.' + act1("Fortune Lady Calling"),
"Fortune Lady Water": base(300) + ' Si esta carta es Invocada de Modo Especial mientras controlas un monstruo ' + F + ' excepto "Fortune Lady Water": roba 2 cartas.',
"Fortune Lady Light": base(200) + ' Cuando esta carta boca arriba deje el Campo por un efecto de carta: puedes Invocar de Modo Especial 1 monstruo ' + F + ' de tu Deck.',
"Fortune Lady Dark": base(400) + ' Cuando tu monstruo ' + F + ' destruya en batalla un monstruo del adversario y lo mande al Cementerio: puedes seleccionar 1 monstruo ' + F + ' en tu Cementerio; Invócalo de Modo Especial.',
"Fortune Lady Past": base(200) + ' Puedes seleccionar 1 monstruo ' + F + ' que controles; destierra cualquier número de otros monstruos de Tipo Lanzador de Conjuros de tu mano, Campo y/o Cementerio y, si lo haces, aumenta o reduce el Nivel de ese monstruo en el número de monstruos desterrados, hasta el final de este turno.' + once("Fortune Lady Past"),
"Fortune Lady Every": '1 Cantante + 1 o más monstruos de Tipo Lanzador de Conjuros que no sean Cantantes\nEl ATK/DEF de esta carta pasan a ser su Nivel x 400. Una vez por turno, durante tu Standby Phase: aumenta el Nivel de esta carta en 1 (máx. 12) y, después, puedes desterrar 1 monstruo boca arriba que controle tu adversario. Durante la End Phase de tu adversario, si esta carta está en tu Cementerio: puedes desterrar otro monstruo de Tipo Lanzador de Conjuros de tu Cementerio; Invoca esta carta de Modo Especial.' + once("Fortune Lady Every"),
"Fortune Lady Fire": base(200) + ' Cuando esta carta sea Invocada de Modo Especial en Posición de Ataque por el efecto de una carta ' + F + ': selecciona 1 monstruo boca arriba que controle tu adversario; destruye ese objetivo y, si lo haces, inflige a tu adversario daño igual al ATK que tenía en el Campo el monstruo destruido.',
"Fortune Lady Wind": base(300) + ' Cuando esta carta sea Invocada de Modo Normal: puedes destruir Mágicas/Trampas que controle tu adversario, igual al número de monstruos ' + F + ' que controles.',
"Fortune Lady Earth": base(400) + ' Si el Nivel de esta carta aumenta: inflige 400 de daño a tu adversario.',
"Fortune Lady Rewind": 'Selecciona cualquier número de tus monstruos ' + F + ' desterrados con nombres diferentes; Invócalos de Modo Especial, pero barájalos en el Deck durante la End Phase.' + act1("Fortune Lady Rewind"),
}
