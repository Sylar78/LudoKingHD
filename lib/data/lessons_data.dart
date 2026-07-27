class LessonStep {
  final String title;
  final String body;
  final String? imageName; // optional asset illustration

  const LessonStep(
      {required this.title, required this.body, this.imageName});
}

class Lesson {
  final int id;
  final String title;
  final String icon;
  final List<LessonStep> steps;

  const Lesson(
      {required this.id,
      required this.title,
      required this.icon,
      required this.steps});
}

const List<Lesson> kLessons = [
  Lesson(
    id: 1,
    title: "Le plateau",
    icon: "🎯",
    steps: [
      LessonStep(
          title: "4 couleurs",
          body:
              "Le plateau comporte 4 zones colorées : Rouge, Bleu, Vert et Jaune. Chaque joueur possède 4 pions de sa couleur."),
      LessonStep(
          title: "La base",
          body:
              "Au départ, tous les pions se trouvent dans la base (le coin coloré). Ils ne peuvent pas bouger tant qu'ils n'ont pas été sortis."),
      LessonStep(
          title: "La piste extérieure",
          body:
              "La piste extérieure est commune à tous : 52 cases forment un chemin circulaire sur lequel les pions avancent."),
      LessonStep(
          title: "La ligne finale",
          body:
              "Après un tour complet, le pion entre dans la ligne colorée de son équipe. Personne ne peut le capturer ici."),
      LessonStep(
          title: "Le centre",
          body:
              "La case centrale est l'arrivée. Un pion qui atteint le centre avec le compte exact a gagné sa course !"),
    ],
  ),
  Lesson(
    id: 2,
    title: "Sortir un pion",
    icon: "🚪",
    steps: [
      LessonStep(
          title: "Pions en base",
          body:
              "Tant qu'un pion est en base, il ne peut pas avancer. Il doit d'abord être sorti."),
      LessonStep(
          title: "Il faut un 6",
          body:
              "Pour faire sortir un pion de la base, il faut obtenir un 6 lors du lancer de dé."),
      LessonStep(
          title: "Sortir ou avancer ?",
          body:
              "Lorsque tu fais un 6, tu peux choisir : sortir un nouveau pion OU avancer un pion déjà sur le plateau."),
      LessonStep(
          title: "Rejouer",
          body:
              "Chaque fois que tu fais un 6, tu rejoues immédiatement. C'est un avantage précieux !"),
    ],
  ),
  Lesson(
    id: 3,
    title: "Déplacer les pions",
    icon: "👟",
    steps: [
      LessonStep(
          title: "Le dé commande",
          body:
              "Le résultat du dé indique exactement combien de cases avancer. Ni plus, ni moins."),
      LessonStep(
          title: "Choisir quel pion",
          body:
              "Quand tu as plusieurs pions sur le plateau, c'est toi qui choisis lequel déplacer. C'est là que commence la stratégie !"),
      LessonStep(
          title: "Sens du déplacement",
          body:
              "Les pions avancent toujours dans le même sens, dans le sens des aiguilles d'une montre sur la piste extérieure."),
    ],
  ),
  Lesson(
    id: 4,
    title: "Capturer un adversaire",
    icon: "⚔️",
    steps: [
      LessonStep(
          title: "L'attaque",
          body:
              "Si ton pion arrive exactement sur une case occupée par un pion adverse, l'adversaire retourne en base !"),
      LessonStep(
          title: "Récompense",
          body:
              "Après une capture, tu rejoues immédiatement. Une bonne capture peut changer le cours de la partie."),
      LessonStep(
          title: "Retour en base",
          body:
              "Le pion capturé doit reprendre depuis zéro : il lui faudra un 6 pour ressortir de la base."),
    ],
  ),
  Lesson(
    id: 5,
    title: "Les cases protégées",
    icon: "⭐",
    steps: [
      LessonStep(
          title: "Safe Zones",
          body:
              "Certaines cases sont marquées d'une étoile. Ce sont des zones protégées (Safe Zones)."),
      LessonStep(
          title: "Pas de capture ici",
          body:
              "Sur une Safe Zone, aucun pion ne peut être capturé. Tout le monde peut s'y arrêter en sécurité."),
      LessonStep(
          title: "Stratégie",
          body:
              "Placer ses pions sur des Safe Zones est souvent une bonne tactique pour les protéger en attendant une meilleure opportunité."),
    ],
  ),
  Lesson(
    id: 6,
    title: "Les règles du 6",
    icon: "🎲",
    steps: [
      LessonStep(
          title: "6 = avantage",
          body:
              "Obtenir un 6 te donne deux avantages : tu avances de 6 cases ET tu relances le dé."),
      LessonStep(
          title: "Plusieurs 6 de suite",
          body:
              "Tu peux enchaîner deux 6 de suite : chaque fois tu rejoues. Mais attention au troisième..."),
      LessonStep(
          title: "Trois 6 consécutifs",
          body:
              "Si tu fais trois 6 d'affilée, le troisième est annulé. Ton tour prend fin sans déplacement bonus."),
    ],
  ),
  Lesson(
    id: 7,
    title: "La ligne d'arrivée",
    icon: "🏠",
    steps: [
      LessonStep(
          title: "Entrée dans la ligne",
          body:
              "Après un tour complet de la piste extérieure, ton pion entre dans la ligne colorée de ta couleur."),
      LessonStep(
          title: "Zone sécurisée",
          body:
              "Dans la ligne d'arrivée, personne ne peut capturer tes pions. Tu es en sécurité !"),
      LessonStep(
          title: "Avancer doucement",
          body:
              "Tu dois avancer case par case dans la ligne. Le compte exact est nécessaire pour atteindre le centre."),
    ],
  ),
  Lesson(
    id: 8,
    title: "Atteindre le centre",
    icon: "🏆",
    steps: [
      LessonStep(
          title: "Compte exact",
          body:
              "Pour entrer au centre, tu dois obtenir exactement le nombre de cases manquantes. Un tir trop fort, et le pion attend !"),
      LessonStep(
          title: "Exemple",
          body:
              "S'il reste 3 cases et que tu fais 5, tu ne peux pas avancer. Il faudra attendre le prochain lancer."),
      LessonStep(
          title: "Rejouer en arrivant",
          body:
              "Quand un pion atteint le centre, tu as droit à un lancer supplémentaire pour avancer un autre pion."),
    ],
  ),
  Lesson(
    id: 9,
    title: "Les blocs",
    icon: "🔒",
    steps: [
      LessonStep(
          title: "Empiler deux pions",
          body:
              "Si deux de tes pions se retrouvent sur la même case, ils forment un bloc."),
      LessonStep(
          title: "Bloc infranchissable",
          body:
              "Un bloc adverse ne peut pas être capturé et bloque le passage des autres joueurs."),
      LessonStep(
          title: "Stratégie avancée",
          body:
              "Créer un bloc sur une case stratégique peut paralyser un adversaire pendant plusieurs tours."),
    ],
  ),
  Lesson(
    id: 10,
    title: "Comment gagner",
    icon: "🥇",
    steps: [
      LessonStep(
          title: "Objectif",
          body:
              "Le premier joueur à placer ses 4 pions au centre remporte la partie !"),
      LessonStep(
          title: "Continuer",
          body:
              "Les autres joueurs peuvent continuer à jouer pour se départager aux 2ème, 3ème et 4ème places."),
      LessonStep(
          title: "Stratégie globale",
          body:
              "Équilibrez votre jeu : sortez les pions rapidement, protégez-les sur les Safe Zones, capturez les adversaires et formez des blocs. Bonne chance !"),
    ],
  ),
];
