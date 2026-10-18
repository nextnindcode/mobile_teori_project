class EclipseCard {
  final int id;
  final String name;
  final int cost;
  final String initial; 

  EclipseCard({
    required this.id,
    required this.name,
    required this.cost,
    required this.initial,
  });
}

// Daftar Kartu Member Eclipse (Belum menggunakan gambar member baru inisial huruf)
final List<EclipseCard> dummyCards = [
  EclipseCard(id: 1, name: 'Solen (Leader)', cost: 100, initial: 'S'),
  EclipseCard(id: 2, name: 'Lunar (Vocalist)', cost: 150, initial: 'L'),
  EclipseCard(id: 3, name: 'Astra (Vocalist)', cost: 200, initial: 'A'),
  
  EclipseCard(id: 4, name: 'Orion (Main Dancer)', cost: 300, initial: 'O'),
  EclipseCard(id: 5, name: 'Vega (Lead Dancer)', cost: 350, initial: 'V'),
  EclipseCard(id: 6, name: 'Nova (Dancer)', cost: 400, initial: 'N'),
  
  EclipseCard(id: 7, name: 'Zephyr (Main Rapper)', cost: 500, initial: 'Z'),
  EclipseCard(id: 8, name: 'Atlas (Lead Rapper)', cost: 550, initial: 'A'),
  EclipseCard(id: 9, name: 'Lyra (Rapper)', cost: 600, initial: 'L'),
  EclipseCard(id: 10, name: 'Cassio (Visual)', cost: 700, initial: 'C'),
  
  EclipseCard(id: 11, name: 'Rigel (Producer)', cost: 850, initial: 'R'),
  EclipseCard(id: 12, name: 'Altair (Guitarist)', cost: 950, initial: 'A'),
  EclipseCard(id: 13, name: 'Mira (Maknae)', cost: 1000, initial: 'M'),
];