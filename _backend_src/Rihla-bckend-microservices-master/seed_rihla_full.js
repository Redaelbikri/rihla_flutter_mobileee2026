// Run:
// mongosh mongodb://localhost:27017 seed_rihla_big.js

// ---------- Helpers ----------
function randomChoice(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
}
function randomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}
function pad2(n) { return (n < 10 ? "0" : "") + n; }
function nowPlusDays(d) { return new Date(Date.now() + d * 86400000); }

// Moroccan-ish data
const cities = ["Casablanca","Rabat","Marrakech","Fès","Tanger","Agadir","Oujda","Essaouira","Meknès","Nador","Tétouan","El Jadida","Laâyoune","Safi","Kénitra"];
const firstNames = ["Amine","Zakaria","Reda","Sara","Imane","Youssef","Omar","Hind","Salma","Karim","Nadia","Anas","Aya","Ilyas","Kawtar","Mehdi","Soukaina","Hamza"];
const lastNames  = ["Ouazzou","Benyamna","Elbikri","Alaoui","Benali","El Idrissi","Chakiri","Tahiri","Boussaid","Haddad","Amrani","Bennis","Lahlou","Zerouali"];
const streetNames = ["Avenue Mohammed V","Boulevard Zerktouni","Rue Al Massira","Avenue Hassan II","Route de la Corniche","Rue Ibn Battouta","Avenue des FAR"];
const eventTitles = ["Mawazine Live","Gnaoua Night","Startup Conference","Derby Match","Film Festival","Tech Meetup","Jazz Evening","Art Expo","Marathon City Run","Food Fest"];
const hotelNames  = ["Riad Atlas","Hotel Ocean View","Riad Medina","Hotel Royal","Dar Souiri","Atlas Resort","Riad Andalouse","Kasbah Lodge","Palm Hotel","Riad Sahara"];
const providers = ["ONCF","CTM"];

// NOTE: Password hash is bcrypt for "User12345" (example). If your auth differs, adapt.
const BCRYPT_USER = "$2b$10$Fh16xNzkywiW68Kws7w9De5h5SoYfiHeZX2SJQYZfkVShPxXEdH82";
// Admin hash for "Admin12345" (you can change)
const BCRYPT_ADMIN = "$2b$10$oYfBR8PC0kKen1c0xWhgbu22aoIAa5h7cBwN2boEkWbYlE6DaGacG";

// ---------- Volumes (change if you want bigger/smaller) ----------
const V = {
    users: 200,
    hebergements: 80,
    events: 120,
    trips: 150,
    reservations: 300,
    payments: 300,
    notifications: 400,
    reviews: 220
};

// ---------- DB names (adjust ONLY if your project uses different names) ----------
const DBS = {
    users: "rihla_users_db",
    hebergements: "rihla_hebergements_db",
    events: "rihla_events_db",
    transport: "rihla_transport_db",
    reservations: "rihla_reservation_db",
    payments: "rihla_payments",
    notifications: "rihla_notifications",
    reviews: "rihla_reviews_db" // if you don't have review-service, ignore or delete this part
};

// ---------- 1) USERS ----------
const usersDb = db.getSiblingDB(DBS.users);
usersDb.users.drop();

let users = [];

// fixed admin
users.push({
    _id: "U-ADMIN",
    nom: "Admin",
    prenom: "Rihla",
    email: "admin@rihla.ma",
    motDePasse: BCRYPT_ADMIN,
    telephone: "0600000000",
    roles: ["ROLE_ADMIN"],
    dateCreation: new Date(),
    statut: "ACTIF"
});

for (let i = 1; i <= V.users; i++) {
    const prenom = randomChoice(firstNames);
    const nom = randomChoice(lastNames);
    const city = randomChoice(cities);
    users.push({
        _id: "U-" + pad2(i) + "-" + randomInt(1000,9999),
        nom,
        prenom,
        email: (prenom.toLowerCase() + "." + nom.toLowerCase() + i + "@rihla.ma").replace(/ /g,""),
        motDePasse: BCRYPT_USER,
        telephone: "06" + randomInt(10000000, 99999999),
        roles: ["ROLE_USER"],
        dateCreation: nowPlusDays(-randomInt(1, 120)),
        statut: "ACTIF",
        ville: city
    });
}

usersDb.users.insertMany(users);

// build list of userSubjects (some services store email as subject)
const userSubjects = users.filter(u => u.roles.includes("ROLE_USER")).map(u => u.email);

// ---------- 2) HEBERGEMENTS ----------
const hebDb = db.getSiblingDB(DBS.hebergements);
hebDb.hebergements.drop();

let hebergements = [];
for (let i = 1; i <= V.hebergements; i++) {
    const ville = randomChoice(cities);
    hebergements.push({
        _id: "H-" + pad2(i) + "-" + randomInt(1000,9999),
        nom: randomChoice(hotelNames) + " " + ville,
        ville,
        adresse: randomChoice(streetNames) + ", " + ville,
        type: randomChoice(["HOTEL","RIAD","APPARTEMENT"]),
        prixParNuit: randomInt(200, 1500),
        chambresDisponibles: randomInt(5, 80),
        note: Number((Math.random() * 2 + 3).toFixed(1)), // 3.0 - 5.0
        imageUrl: "https://picsum.photos/seed/heb" + i + "/900/600",
        actif: true
    });
}
hebDb.hebergements.insertMany(hebergements);

// ---------- 3) EVENTS ----------
const eventsDb = db.getSiblingDB(DBS.events);
eventsDb.events.drop();

let events = [];
for (let i = 1; i <= V.events; i++) {
    const ville = randomChoice(cities);
    const title = randomChoice(eventTitles);
    events.push({
        _id: "E-" + pad2(i) + "-" + randomInt(1000,9999),
        nom: title + " " + ville,
        description: "Événement à " + ville + " (Musique/Sport/Culture).",
        lieu: randomChoice(streetNames) + ", " + ville,
        categorie: randomChoice(["MUSIC","SPORT","FESTIVAL","CONFERENCE","CULTURE"]),
        dateEvent: nowPlusDays(randomInt(1, 220)),
        prix: randomInt(0, 600),
        placesDisponibles: randomInt(200, 15000),
        imageUrl: "https://picsum.photos/seed/event" + i + "/900/600"
    });
}
eventsDb.events.insertMany(events);

// ---------- 4) TRANSPORT / TRIPS ----------
const trDb = db.getSiblingDB(DBS.transport);
trDb.trips.drop();

let trips = [];
for (let i = 1; i <= V.trips; i++) {
    let fromCity = randomChoice(cities);
    let toCity = randomChoice(cities);
    while (toCity === fromCity) toCity = randomChoice(cities);

    const type = randomChoice(["TRAIN","BUS"]);
    const providerName = (type === "TRAIN") ? "ONCF" : "CTM";
    const dep = nowPlusDays(randomInt(1, 90));
    const durationMin = (type === "TRAIN") ? randomInt(50, 240) : randomInt(90, 420);
    const arr = new Date(dep.getTime() + durationMin * 60000);

    const capacity = (type === "TRAIN") ? randomInt(200, 450) : randomInt(40, 60);
    const availableSeats = randomInt(0, capacity);

    trips.push({
        _id: "T-" + pad2(i) + "-" + randomInt(1000,9999),
        fromCity,
        toCity,
        departureAt: dep,
        arrivalAt: arr,
        type,
        price: NumberDecimal(String(randomInt(50, 250)) + ".00"),
        currency: "MAD",
        capacity,
        availableSeats,
        providerName
    });
}
trDb.trips.insertMany(trips);

// ---------- 5) RESERVATIONS ----------
const resDb = db.getSiblingDB(DBS.reservations);
resDb.reservations.drop();

let reservations = [];
for (let i = 1; i <= V.reservations; i++) {
    const userSubject = randomChoice(userSubjects);

    // Choose reservation type distribution
    const kind = randomChoice(["TRANSPORT","EVENT","HEBERGEMENT","MIXED"]); // MIXED = event+heb for realism
    const status = randomChoice(["PENDING_PAYMENT","CONFIRMED","CANCELLED"]);
    const paymentStatus =
        (status === "CONFIRMED") ? "SUCCEEDED"
            : (status === "CANCELLED") ? randomChoice(["FAILED","CANCELLED"])
                : randomChoice(["CREATED","REQUIRES_PAYMENT_METHOD","CREATED"]);

    let transportTripId = null, transportSeats = null;
    let hebergementId = null, hebergementRooms = null;
    let eventId = null, eventTickets = null;

    if (kind === "TRANSPORT") {
        const trip = randomChoice(trips);
        transportTripId = trip._id;
        transportSeats = randomInt(1, 3);
    } else if (kind === "EVENT") {
        const ev = randomChoice(events);
        eventId = ev._id;
        eventTickets = randomInt(1, 4);
    } else if (kind === "HEBERGEMENT") {
        const heb = randomChoice(hebergements);
        hebergementId = heb._id;
        hebergementRooms = randomInt(1, 2);
    } else { // MIXED
        const ev = randomChoice(events);
        const heb = randomChoice(hebergements);
        eventId = ev._id;
        eventTickets = randomInt(1, 3);
        hebergementId = heb._id;
        hebergementRooms = randomInt(1, 2);
    }

    reservations.push({
        _id: "R-" + pad2(i) + "-" + randomInt(1000,9999),
        userSubject,
        status,
        paymentStatus,
        createdAt: nowPlusDays(-randomInt(0, 60)),
        transportTripId,
        transportSeats,
        hebergementId,
        hebergementRooms,
        eventId,
        eventTickets
    });
}
resDb.reservations.insertMany(reservations);

// ---------- 6) PAYMENTS ----------
const payDb = db.getSiblingDB(DBS.payments);
payDb.payments.drop();

let payments = [];
for (let i = 1; i <= V.payments; i++) {
    const r = randomChoice(reservations);
    const status = randomChoice(["CREATED","SUCCEEDED","FAILED","CANCELLED","REQUIRES_PAYMENT_METHOD"]);
    const amountCents = randomInt(5000, 350000); // 50 MAD - 3500 MAD in cents

    payments.push({
        _id: "P-" + pad2(i) + "-" + randomInt(1000,9999),
        userSubject: r.userSubject,
        reservationId: r._id,
        paymentIntentId: "pi_test_rihla_" + i + "_" + randomInt(1000,9999),
        amount: NumberLong(amountCents),
        currency: "mad",
        status,
        provider: "STRIPE_TEST",
        createdAt: nowPlusDays(-randomInt(0, 60)),
        updatedAt: new Date()
    });
}
payDb.payments.insertMany(payments);

// ---------- 7) NOTIFICATIONS ----------
const notifDb = db.getSiblingDB(DBS.notifications);
notifDb.notifications.drop();

const notifTypes = ["PAYMENT_CREATED","PAYMENT_SUCCEEDED","PAYMENT_FAILED","RESERVATION_CONFIRMED","EVENT_REMINDER","TRIP_REMINDER"];
let notifications = [];

for (let i = 1; i <= V.notifications; i++) {
    const u = randomChoice(userSubjects);
    const type = randomChoice(notifTypes);
    const read = Math.random() < 0.35;

    let title = "Notification";
    let message = "Mise à jour Rihla.";
    if (type === "PAYMENT_SUCCEEDED") { title = "Paiement réussi"; message = "Votre paiement a été confirmé ✅"; }
    if (type === "PAYMENT_FAILED") { title = "Paiement échoué"; message = "Votre paiement a échoué ❌"; }
    if (type === "PAYMENT_CREATED") { title = "Paiement créé"; message = "Votre paiement est en cours ⏳"; }
    if (type === "RESERVATION_CONFIRMED") { title = "Réservation confirmée"; message = "Votre réservation est confirmée 🎉"; }
    if (type === "EVENT_REMINDER") { title = "Rappel événement"; message = "N’oubliez pas votre événement قريباً 🎫"; }
    if (type === "TRIP_REMINDER") { title = "Rappel trajet"; message = "Votre trajet arrive bientôt 🚆"; }

    notifications.push({
        _id: "N-" + pad2(i) + "-" + randomInt(1000,9999),
        userSubject: u,
        type,
        title,
        message,
        read,
        createdAt: nowPlusDays(-randomInt(0, 30)),
        sourceKey: "seed:" + type,
        sourceEventId: "SEED-" + i
    });
}
notifDb.notifications.insertMany(notifications);


print("✅ RIHLA BIG SEED DONE");
print("DBs: " + JSON.stringify(DBS));
print("Volumes: " + JSON.stringify(V));
