// Script de depuración para verificar tareas
// Ejecutar en la consola de Firebase o en DevTools

// Verificar en la consola del navegador qué tareas existen para el usuario
import { getFirestore, collection, query, where, getDocs } from 'firebase/firestore';

async function debugUserTasks(userId) {
  const db = getFirestore();
  
  console.log('=== DEBUG: Verificando tareas para usuario:', userId);
  
  // Query 1: Todas las tareas asignadas al usuario
  const q1 = query(
    collection(db, 'tasks'),
    where('assignedTo', '==', userId)
  );
  
  const snapshot1 = await getDocs(q1);
  console.log('Total tareas asignadas:', snapshot1.size);
  
  snapshot1.forEach(doc => {
    const data = doc.data();
    console.log('---');
    console.log('ID:', doc.id);
    console.log('Título:', data.title);
    console.log('Estado:', data.status);
    console.log('isPersonal:', data.isPersonal);
    console.log('assignedTo:', data.assignedTo);
    console.log('createdBy:', data.createdBy);
  });
  
  // Query 2: Tareas pendientes
  const q2 = query(
    collection(db, 'tasks'),
    where('assignedTo', '==', userId),
    where('status', '==', 'pending')
  );
  
  const snapshot2 = await getDocs(q2);
  console.log('\nTareas PENDIENTES:', snapshot2.size);
  
  // Query 3: Tareas en progreso
  const q3 = query(
    collection(db, 'tasks'),
    where('assignedTo', '==', userId),
    where('status', '==', 'in_progress')
  );
  
  const snapshot3 = await getDocs(q3);
  console.log('Tareas EN PROGRESO:', snapshot3.size);
  
  // Query 4: Tareas completadas
  const q4 = query(
    collection(db, 'tasks'),
    where('assignedTo', '==', userId),
    where('status', '==', 'completed')
  );
  
  const snapshot4 = await getDocs(q4);
  console.log('Tareas COMPLETADAS:', snapshot4.size);
}

// Uso: Reemplazar 'USER_ID' con el UID real del usuario yuri
// debugUserTasks('USER_ID');
