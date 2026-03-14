// ============================================================
// RIHLA — REAL DATA SEED SCRIPT
// Run: mongosh "mongodb://localhost:27017" seed_real_data.js
// ============================================================

print("=".repeat(60));
print("RIHLA REAL DATA SEED — Starting...");
print("=".repeat(60));

// ──────────────────────────────────────────────────────────────
// STEP 0 — DROP ALL OLD DATA
// ──────────────────────────────────────────────────────────────

db = db.getSiblingDB("rihla_users_db");        db.users.drop();
db = db.getSiblingDB("rihla_hebergements_db"); db.hebergements.drop();
db = db.getSiblingDB("rihla_events_db");       db.events.drop();
db = db.getSiblingDB("rihla_transport_db");    db.trips.drop();
db = db.getSiblingDB("rihla_reservation_db");  db.reservations.drop();
db = db.getSiblingDB("rihla_payments");        db.payments.drop();
db = db.getSiblingDB("rihla_notifications");   db.notifications.drop();
db = db.getSiblingDB("rihla_itinerary");       db.itineraries.drop();
db = db.getSiblingDB("rihla_assistant");       db.chat_messages.drop();
db = db.getSiblingDB("rihla");                 db.reviews.drop();

print("✓ All old collections dropped");

// ──────────────────────────────────────────────────────────────
// STEP 1 — USERS  (rihla_users_db)
// Passwords:  Admin12345  →  adminHash
//             User12345   →  userHash
// ──────────────────────────────────────────────────────────────

db = db.getSiblingDB("rihla_users_db");

const adminHash = "$2b$10$oYfBR8PC0kKen1c0xWhgbu22aoIAa5h7cBwN2boEkWbYlE6DaGacG";
const userHash  = "$2b$10$Fh16xNzkywiW68Kws7w9De5h5SoYfiHeZX2SJQYZfkVShPxXEdH82";

db.users.insertMany([
  {
    _id: "admin-rihla-001",
    nom: "Admin", prenom: "Rihla",
    email: "admin@rihla.ma",
    motDePasse: adminHash,
    telephone: "0522000000",
    roles: ["ROLE_ADMIN"],
    provider: "LOCAL", enabled: true, statut: "ACTIF",
    dateCreation: new Date("2026-01-01T00:00:00Z")
  },
  {
    _id: "user-001",
    nom: "Benyamna", prenom: "Zakaria",
    email: "zakaria.benyamna@test.ma",
    motDePasse: userHash,
    telephone: "0661234567",
    roles: ["ROLE_USER"],
    provider: "LOCAL", enabled: true, statut: "ACTIF",
    dateCreation: new Date("2026-01-15T10:00:00Z")
  },
  {
    _id: "user-002",
    nom: "Alaoui", prenom: "Sara",
    email: "sara.alaoui@test.ma",
    motDePasse: userHash,
    telephone: "0662345678",
    roles: ["ROLE_USER"],
    provider: "LOCAL", enabled: true, statut: "ACTIF",
    dateCreation: new Date("2026-01-20T11:00:00Z")
  },
  {
    _id: "user-003",
    nom: "Benali", prenom: "Youssef",
    email: "youssef.benali@test.ma",
    motDePasse: userHash,
    telephone: "0663456789",
    roles: ["ROLE_USER"],
    provider: "LOCAL", enabled: true, statut: "ACTIF",
    dateCreation: new Date("2026-02-01T09:00:00Z")
  },
  {
    _id: "user-004",
    nom: "Tahiri", prenom: "Imane",
    email: "imane.tahiri@test.ma",
    motDePasse: userHash,
    telephone: "0664567890",
    roles: ["ROLE_USER"],
    provider: "LOCAL", enabled: true, statut: "ACTIF",
    dateCreation: new Date("2026-02-10T14:00:00Z")
  }
]);
print("✓ Users: " + db.users.countDocuments() + " inserted");

// ──────────────────────────────────────────────────────────────
// STEP 2 — HEBERGEMENTS  (rihla_hebergements_db)
// ──────────────────────────────────────────────────────────────

db = db.getSiblingDB("rihla_hebergements_db");

db.hebergements.insertMany([
  {
    _id: "HEB-001",
    nom: "La Mamounia",
    ville: "Marrakech",
    adresse: "Avenue Bab Jdid, Marrakech 40040",
    type: "HOTEL",
    prixParNuit: 2500.0,
    chambresDisponibles: 12,
    note: 4.9,
    imageUrl: "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800",
    actif: true
  },
  {
    _id: "HEB-002",
    nom: "Riad Kniza",
    ville: "Marrakech",
    adresse: "34 Derb l'Hôtel, Bab Doukkala, Marrakech",
    type: "RIAD",
    prixParNuit: 1800.0,
    chambresDisponibles: 8,
    note: 4.8,
    imageUrl: "https://images.unsplash.com/photo-1540518614846-7eded433c457?w=800",
    actif: true
  },
  {
    _id: "HEB-003",
    nom: "Sofitel Rabat Jardin des Roses",
    ville: "Rabat",
    adresse: "Rue Souss, Quartier Hassan, Rabat",
    type: "HOTEL",
    prixParNuit: 1200.0,
    chambresDisponibles: 20,
    note: 4.7,
    imageUrl: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
    actif: true
  },
  {
    _id: "HEB-004",
    nom: "Riad Fes",
    ville: "Fès",
    adresse: "5 Derb Bensalem, Zerbtana, Fès Médina",
    type: "RIAD",
    prixParNuit: 1500.0,
    chambresDisponibles: 10,
    note: 4.8,
    imageUrl: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800",
    actif: true
  },
  {
    _id: "HEB-005",
    nom: "Kenzi Tower Hotel",
    ville: "Casablanca",
    adresse: "Boulevard Mohammed Zerktouni, Casablanca",
    type: "HOTEL",
    prixParNuit: 900.0,
    chambresDisponibles: 30,
    note: 4.5,
    imageUrl: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800",
    actif: true
  },
  {
    _id: "HEB-006",
    nom: "Dar Roumana",
    ville: "Fès",
    adresse: "30 Derb el Amer, Fondouk Lihoudi, Fès",
    type: "RIAD",
    prixParNuit: 800.0,
    chambresDisponibles: 6,
    note: 4.7,
    imageUrl: "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800",
    actif: true
  },
  {
    _id: "HEB-007",
    nom: "Barceló Tanger",
    ville: "Tanger",
    adresse: "Place de France, Tanger",
    type: "HOTEL",
    prixParNuit: 750.0,
    chambresDisponibles: 25,
    note: 4.3,
    imageUrl: "https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800",
    actif: true
  },
  {
    _id: "HEB-008",
    nom: "Dar Zitoun",
    ville: "Chefchaouen",
    adresse: "Rue Targha, Médina de Chefchaouen",
    type: "MAISON_HOTE",
    prixParNuit: 400.0,
    chambresDisponibles: 5,
    note: 4.6,
    imageUrl: "https://images.unsplash.com/photo-1489493887464-892be6d1daae?w=800",
    actif: true
  },
  {
    _id: "HEB-009",
    nom: "Résidence Les Dunes d'Or",
    ville: "Agadir",
    adresse: "Boulevard du 20 Août, Agadir",
    type: "APPARTEMENT",
    prixParNuit: 550.0,
    chambresDisponibles: 15,
    note: 4.2,
    imageUrl: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
    actif: true
  },
  {
    _id: "HEB-010",
    nom: "Palais Amani",
    ville: "Fès",
    adresse: "12 Derb El Miter, El Adoua, Fès",
    type: "HOTEL",
    prixParNuit: 1300.0,
    chambresDisponibles: 14,
    note: 4.9,
    imageUrl: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
    actif: true
  }
]);
print("✓ Hebergements: " + db.hebergements.countDocuments() + " inserted");

// ──────────────────────────────────────────────────────────────
// STEP 3 — EVENTS  (rihla_events_db)
// ──────────────────────────────────────────────────────────────

db = db.getSiblingDB("rihla_events_db");

db.events.insertMany([
  {
    _id: "EVT-001",
    nom: "Festival Gnaoua et Musiques du Monde",
    description: "Le plus grand festival de musique Gnaoua au monde. Trois jours de concerts gratuits sur la place Moulay Hassan, mêlant musique traditionnelle Gnaoua et artistes internationaux.",
    lieu: "Essaouira",
    categorie: "Musique",
    dateEvent: new Date("2026-06-18T18:00:00Z"),
    prix: 0.0,
    placesDisponibles: 5000,
    imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800"
  },
  {
    _id: "EVT-002",
    nom: "Festival de Fès des Musiques Sacrées du Monde",
    description: "Un festival unique dédié aux musiques sacrées du monde entier. Concerts dans la Cour de Batha et d'autres lieux emblématiques de la médina de Fès.",
    lieu: "Fès",
    categorie: "Musique",
    dateEvent: new Date("2026-06-05T19:30:00Z"),
    prix: 150.0,
    placesDisponibles: 800,
    imageUrl: "https://images.unsplash.com/photo-1501386761578-eaa54b595e50?w=800"
  },
  {
    _id: "EVT-003",
    nom: "Festival International du Film de Marrakech (FIFM)",
    description: "Le plus grand festival de cinéma d'Afrique et du monde arabe. Projections, hommages et rencontres avec les plus grandes stars du cinéma mondial.",
    lieu: "Marrakech",
    categorie: "Cinéma",
    dateEvent: new Date("2026-11-13T20:00:00Z"),
    prix: 100.0,
    placesDisponibles: 1200,
    imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800"
  },
  {
    _id: "EVT-004",
    nom: "Festival Timitar — Musiques et Rencontres",
    description: "Festival international dédié aux musiques amazighes et du monde. La scène principale accueille des artistes de renommée internationale sur la place Al Amal.",
    lieu: "Agadir",
    categorie: "Musique",
    dateEvent: new Date("2026-07-08T20:00:00Z"),
    prix: 0.0,
    placesDisponibles: 10000,
    imageUrl: "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800"
  },
  {
    _id: "EVT-005",
    nom: "L'Boulevard — Festival Urbain",
    description: "Le festival incontournable des musiques urbaines au Maroc. Hip-hop, reggae, rock, electro : trois jours de musique live à l'Office Chérifien des Phosphates.",
    lieu: "Casablanca",
    categorie: "Musique",
    dateEvent: new Date("2026-10-01T17:00:00Z"),
    prix: 200.0,
    placesDisponibles: 3000,
    imageUrl: "https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=800"
  },
  {
    _id: "EVT-006",
    nom: "Moussem de Moulay Idriss Zerhoun",
    description: "Le plus grand moussem religieux du Maroc, en l'honneur du fondateur de la ville de Fès. Pèlerinage, fantasia et artisanat traditionnel.",
    lieu: "Moulay Idriss Zerhoun",
    categorie: "Culturel",
    dateEvent: new Date("2026-09-10T10:00:00Z"),
    prix: 0.0,
    placesDisponibles: 20000,
    imageUrl: "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800"
  },
  {
    _id: "EVT-007",
    nom: "Nuits du Ramadan — Fès Médina",
    description: "Spectacles de musique andalouse et soirées culturelles dans les plus beaux palais de la médina de Fès pendant le mois sacré du Ramadan.",
    lieu: "Fès",
    categorie: "Culturel",
    dateEvent: new Date("2026-03-15T21:00:00Z"),
    prix: 80.0,
    placesDisponibles: 400,
    imageUrl: "https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800"
  }
]);
print("✓ Events: " + db.events.countDocuments() + " inserted");

// ──────────────────────────────────────────────────────────────
// STEP 4 — TRANSPORT TRIPS  (rihla_transport_db)
// Providers: ONCF (trains), CTM (buses)
// Currency: MAD
// ──────────────────────────────────────────────────────────────

db = db.getSiblingDB("rihla_transport_db");

db.trips.insertMany([

  // ── Casablanca ↔ Rabat (ONCF Train — ~1h15) ──────────────
  {
    _id: "TR-001",
    fromCity: "Casablanca", toCity: "Rabat",
    departureAt: new Date("2026-03-05T07:00:00Z"),
    arrivalAt:   new Date("2026-03-05T08:15:00Z"),
    type: "TRAIN", price: NumberDecimal("45.00"), currency: "MAD",
    capacity: 200, availableSeats: 180, providerName: "ONCF"
  },
  {
    _id: "TR-002",
    fromCity: "Casablanca", toCity: "Rabat",
    departureAt: new Date("2026-03-05T13:00:00Z"),
    arrivalAt:   new Date("2026-03-05T14:15:00Z"),
    type: "TRAIN", price: NumberDecimal("45.00"), currency: "MAD",
    capacity: 200, availableSeats: 150, providerName: "ONCF"
  },
  {
    _id: "TR-003",
    fromCity: "Rabat", toCity: "Casablanca",
    departureAt: new Date("2026-03-05T18:00:00Z"),
    arrivalAt:   new Date("2026-03-05T19:15:00Z"),
    type: "TRAIN", price: NumberDecimal("45.00"), currency: "MAD",
    capacity: 200, availableSeats: 120, providerName: "ONCF"
  },

  // ── Casablanca → Marrakech (ONCF Train — ~2h45) ──────────
  {
    _id: "TR-004",
    fromCity: "Casablanca", toCity: "Marrakech",
    departureAt: new Date("2026-03-06T07:30:00Z"),
    arrivalAt:   new Date("2026-03-06T10:15:00Z"),
    type: "TRAIN", price: NumberDecimal("95.00"), currency: "MAD",
    capacity: 250, availableSeats: 200, providerName: "ONCF"
  },
  {
    _id: "TR-005",
    fromCity: "Casablanca", toCity: "Marrakech",
    departureAt: new Date("2026-03-06T16:00:00Z"),
    arrivalAt:   new Date("2026-03-06T18:45:00Z"),
    type: "TRAIN", price: NumberDecimal("95.00"), currency: "MAD",
    capacity: 250, availableSeats: 175, providerName: "ONCF"
  },
  {
    _id: "TR-006",
    fromCity: "Marrakech", toCity: "Casablanca",
    departureAt: new Date("2026-03-07T08:00:00Z"),
    arrivalAt:   new Date("2026-03-07T10:45:00Z"),
    type: "TRAIN", price: NumberDecimal("95.00"), currency: "MAD",
    capacity: 250, availableSeats: 190, providerName: "ONCF"
  },

  // ── Casablanca → Tanger (Al Boraq TGV — ~2h10) ───────────
  {
    _id: "TR-007",
    fromCity: "Casablanca", toCity: "Tanger",
    departureAt: new Date("2026-03-06T06:00:00Z"),
    arrivalAt:   new Date("2026-03-06T08:10:00Z"),
    type: "TRAIN", price: NumberDecimal("120.00"), currency: "MAD",
    capacity: 350, availableSeats: 300, providerName: "ONCF Al Boraq"
  },
  {
    _id: "TR-008",
    fromCity: "Casablanca", toCity: "Tanger",
    departureAt: new Date("2026-03-06T14:00:00Z"),
    arrivalAt:   new Date("2026-03-06T16:10:00Z"),
    type: "TRAIN", price: NumberDecimal("120.00"), currency: "MAD",
    capacity: 350, availableSeats: 260, providerName: "ONCF Al Boraq"
  },
  {
    _id: "TR-009",
    fromCity: "Tanger", toCity: "Casablanca",
    departureAt: new Date("2026-03-07T10:00:00Z"),
    arrivalAt:   new Date("2026-03-07T12:10:00Z"),
    type: "TRAIN", price: NumberDecimal("120.00"), currency: "MAD",
    capacity: 350, availableSeats: 280, providerName: "ONCF Al Boraq"
  },

  // ── Rabat → Fès (ONCF Train — ~2h45) ─────────────────────
  {
    _id: "TR-010",
    fromCity: "Rabat", toCity: "Fès",
    departureAt: new Date("2026-03-08T08:30:00Z"),
    arrivalAt:   new Date("2026-03-08T11:15:00Z"),
    type: "TRAIN", price: NumberDecimal("95.00"), currency: "MAD",
    capacity: 200, availableSeats: 160, providerName: "ONCF"
  },
  {
    _id: "TR-011",
    fromCity: "Fès", toCity: "Rabat",
    departureAt: new Date("2026-03-09T17:00:00Z"),
    arrivalAt:   new Date("2026-03-09T19:45:00Z"),
    type: "TRAIN", price: NumberDecimal("95.00"), currency: "MAD",
    capacity: 200, availableSeats: 140, providerName: "ONCF"
  },

  // ── Casablanca → Agadir (CTM Bus — ~8h) ──────────────────
  {
    _id: "TR-012",
    fromCity: "Casablanca", toCity: "Agadir",
    departureAt: new Date("2026-03-10T22:00:00Z"),
    arrivalAt:   new Date("2026-03-11T06:00:00Z"),
    type: "BUS", price: NumberDecimal("120.00"), currency: "MAD",
    capacity: 50, availableSeats: 35, providerName: "CTM"
  },
  {
    _id: "TR-013",
    fromCity: "Agadir", toCity: "Casablanca",
    departureAt: new Date("2026-03-12T22:30:00Z"),
    arrivalAt:   new Date("2026-03-13T06:30:00Z"),
    type: "BUS", price: NumberDecimal("120.00"), currency: "MAD",
    capacity: 50, availableSeats: 40, providerName: "CTM"
  },

  // ── Marrakech → Agadir (CTM Bus — ~3h30) ─────────────────
  {
    _id: "TR-014",
    fromCity: "Marrakech", toCity: "Agadir",
    departureAt: new Date("2026-03-11T09:00:00Z"),
    arrivalAt:   new Date("2026-03-11T12:30:00Z"),
    type: "BUS", price: NumberDecimal("80.00"), currency: "MAD",
    capacity: 50, availableSeats: 30, providerName: "CTM"
  },
  {
    _id: "TR-015",
    fromCity: "Marrakech", toCity: "Agadir",
    departureAt: new Date("2026-03-11T15:00:00Z"),
    arrivalAt:   new Date("2026-03-11T18:30:00Z"),
    type: "BUS", price: NumberDecimal("80.00"), currency: "MAD",
    capacity: 50, availableSeats: 45, providerName: "CTM"
  },

  // ── Fès → Meknès (CTM Bus — ~1h) ──────────────────────────
  {
    _id: "TR-016",
    fromCity: "Fès", toCity: "Meknès",
    departureAt: new Date("2026-03-07T10:00:00Z"),
    arrivalAt:   new Date("2026-03-07T11:00:00Z"),
    type: "BUS", price: NumberDecimal("30.00"), currency: "MAD",
    capacity: 50, availableSeats: 28, providerName: "CTM"
  },
  {
    _id: "TR-017",
    fromCity: "Meknès", toCity: "Fès",
    departureAt: new Date("2026-03-07T16:00:00Z"),
    arrivalAt:   new Date("2026-03-07T17:00:00Z"),
    type: "BUS", price: NumberDecimal("30.00"), currency: "MAD",
    capacity: 50, availableSeats: 22, providerName: "CTM"
  },

  // ── Fès → Oujda (ONCF Train — ~4h) ───────────────────────
  {
    _id: "TR-018",
    fromCity: "Fès", toCity: "Oujda",
    departureAt: new Date("2026-03-08T07:00:00Z"),
    arrivalAt:   new Date("2026-03-08T11:00:00Z"),
    type: "TRAIN", price: NumberDecimal("130.00"), currency: "MAD",
    capacity: 180, availableSeats: 100, providerName: "ONCF"
  },

  // ── Marrakech → Fès (CTM Bus — ~8h30) ────────────────────
  {
    _id: "TR-019",
    fromCity: "Marrakech", toCity: "Fès",
    departureAt: new Date("2026-03-09T21:00:00Z"),
    arrivalAt:   new Date("2026-03-10T05:30:00Z"),
    type: "BUS", price: NumberDecimal("140.00"), currency: "MAD",
    capacity: 50, availableSeats: 20, providerName: "CTM"
  },

  // ── Tanger → Tétouan (CTM Bus — ~1h) ─────────────────────
  {
    _id: "TR-020",
    fromCity: "Tanger", toCity: "Tétouan",
    departureAt: new Date("2026-03-10T09:00:00Z"),
    arrivalAt:   new Date("2026-03-10T10:00:00Z"),
    type: "BUS", price: NumberDecimal("25.00"), currency: "MAD",
    capacity: 50, availableSeats: 38, providerName: "CTM"
  }
]);
print("✓ Trips: " + db.trips.countDocuments() + " inserted");

// ──────────────────────────────────────────────────────────────
// DONE
// ──────────────────────────────────────────────────────────────

print("");
print("=".repeat(60));
print("SUMMARY");
print("=".repeat(60));

db = db.getSiblingDB("rihla_users_db");
print("  users           : " + db.users.countDocuments());
db = db.getSiblingDB("rihla_hebergements_db");
print("  hebergements    : " + db.hebergements.countDocuments());
db = db.getSiblingDB("rihla_events_db");
print("  events          : " + db.events.countDocuments());
db = db.getSiblingDB("rihla_transport_db");
print("  trips           : " + db.trips.countDocuments());

print("");
print("Login credentials:");
print("  Admin  →  admin@rihla.ma          / Admin12345");
print("  Users  →  zakaria.benyamna@test.ma / User12345");
print("           sara.alaoui@test.ma       / User12345");
print("           youssef.benali@test.ma    / User12345");
print("           imane.tahiri@test.ma      / User12345");
print("=".repeat(60));
print("DONE — Run your services now!");