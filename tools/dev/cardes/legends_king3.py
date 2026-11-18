F = '"The Fang of Critias"'
def must(c): return 'Debe ser Invocada de Modo Especial con ' + F + ', usando "%s". ' % c
ES = {
"Doom Virus Dragon": must("Crush Card Virus") + 'Si esta carta es Invocada de Modo Especial: mira la mano de tu adversario, todos los monstruos que controla y todas las cartas que robe hasta el final de su 3er turno después de la activación de este efecto, y destruye todos esos monstruos con 1500 o más ATK.',
"Destruction Dragon": must("Ring of Destruction") + 'Una vez por turno: puedes seleccionar 1 carta que controle tu adversario; destrúyela. Después, si era una Carta de Monstruo, inflige a tu adversario daño igual a su ATK original.',
"Tyrant Burst Dragon": must("Tyrant Wing") + 'Esta carta puede atacar una vez a cada monstruo de tu adversario. Puedes seleccionar 1 monstruo boca arriba que controles; equipa este monstruo a ese objetivo. Gana 400 ATK/DEF; además, puede realizar 3 ataques durante cada Battle Phase.',
"Mirror Force Dragon": must("Mirror Force") + 'Cuando uno o más monstruos que controles sean seleccionados para un ataque o por un efecto de carta del adversario (excepto durante el Damage Step) (Efecto Rápido): puedes destruir todas las cartas que controle tu adversario.',
"Tyrant Wing": 'Selecciona 1 monstruo de Tipo Dragón en el Campo; equipa esta carta a él. Gana 400 ATK/DEF; además, puede realizar hasta 2 ataques a monstruos durante cada Battle Phase. Una vez por turno, durante la End Phase, si el monstruo equipado con esta carta por este efecto atacó a un monstruo del adversario este turno: destruye esta carta.',
}
