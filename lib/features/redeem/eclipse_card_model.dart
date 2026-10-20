class EclipseCard {
  final int id;
  final String name;
  final int cost;
  final String imageUrl; 

  EclipseCard({
    required this.id,
    required this.name,
    required this.cost,
    required this.imageUrl,
  });
}

// Daftar Kartu Member Eclipse 
final List<EclipseCard> dummyCards = [
  EclipseCard(
    id: 1, 
    name: 'Solen (Leader)', 
    cost: 100, 
    imageUrl: 'https://i.pinimg.com/474x/fb/6e/d0/fb6ed0220d312c14338316561f7c5071.jpg'
  ),

  EclipseCard(
    id: 2, 
    name: 'Lunar (Vocalist)', 
    cost: 150, 
    imageUrl: 'https://i.pinimg.com/474x/f5/f7/70/f5f77032f9fec06f0853f5d8a1c932a3.jpg'
  ),

  EclipseCard(
    id: 3, 
    name: 'Astra (Vocalist)', 
    cost: 200, 
    imageUrl: 'https://i.pinimg.com/474x/8c/02/84/8c02848e71b6d5b6b79596ef70e28c1c.jpg'
  ),
  
  EclipseCard(
    id: 4, 
    name: 'Orion (Main Dancer)', 
    cost: 300, 
    imageUrl: 'https://i.pinimg.com/474x/f9/2d/7b/f92d7b246e3791c2a1ce6a73440ab392.jpg'
  ),
  
  EclipseCard(
    id: 5, 
    name: 'Vega (Lead Dancer)', 
    cost: 350, 
    imageUrl: 'https://i.pinimg.com/474x/a2/12/6a/a2126aaea39c2697c9cedb9c6e4bdd36.jpg'
  ),

  EclipseCard(
    id: 6, 
    name: 'Nova (Dancer)', 
    cost: 400, 
    imageUrl: 'https://i.pinimg.com/474x/ac/51/7b/ac517ba571f5aa1e9e2ccaf3a8fd0ccd.jpg'
  ),
  
  EclipseCard(
    id: 7, 
    name: 'Zephyr (Main Rapper)', 
    cost: 500, 
    imageUrl: 'https://i.pinimg.com/474x/01/28/05/0128052d7a22e38efe7a61a789f0069b.jpg'
  ),

  EclipseCard(
    id: 8, 
    name: 'Atlas (Lead Rapper)', 
    cost: 550, 
    imageUrl: 'https://i.pinimg.com/474x/ee/82/72/ee8272c516181958c4b2301c38e860dd.jpg'
  ),

  EclipseCard(
    id: 9, 
    name: 'Lyra (Rapper)', 
    cost: 600, 
    imageUrl: 'https://i.pinimg.com/474x/4b/31/bf/4b31bfa73bb016bce9fcde1a857c0715.jpg'
  ),

  EclipseCard(
    id: 10, 
    name: 'Cassio (Visual)', 
    cost: 700, 
    imageUrl: 'https://i.pinimg.com/474x/ef/8e/7c/ef8e7c8f17ff8f19c3c2ffd0349adcf1.jpg'
  ),
  
  EclipseCard(
    id: 11, 
    name: 'Rigel (Producer)', 
    cost: 850, 
    imageUrl: 'https://i.pinimg.com/474x/00/75/98/007598dff00e3a6bb4f577ddbfa58571.jpg'
  ),

  EclipseCard(
    id: 12, 
    name: 'Altair (Guitarist)', 
    cost: 950, 
    imageUrl: 'https://i.pinimg.com/474x/1d/97/14/1d9714b5b4c7c9d1d87b684744fcbae5.jpg'
    ),
  
  EclipseCard(
    id: 13, 
    name: 'Mira (Maknae)', 
    cost: 1000, 
    imageUrl: 'https://i.pinimg.com/474x/0b/15/21/0b1521c1527d7e29ef832c9c3e6aa18b.jpg'
    ),
];