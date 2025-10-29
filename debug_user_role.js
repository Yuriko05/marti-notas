// Ejecuta esto en la consola del navegador para verificar tu rol
// 1. Abre la app en Chrome
// 2. Presiona F12 para abrir Developer Tools
// 3. Ve a la pestaña "Console"
// 4. Pega este código y presiona Enter

firebase.auth().onAuthStateChanged(async (user) => {
  if (user) {
    console.log('Usuario autenticado:', user.uid);
    console.log('Email:', user.email);
    
    try {
      const userDoc = await firebase.firestore().collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        console.log('Datos del usuario en Firestore:', userData);
        console.log('Rol:', userData.role);
        console.log('¿Es admin?:', userData.role === 'admin');
      } else {
        console.error('No existe documento del usuario en Firestore');
      }
    } catch (error) {
      console.error('Error obteniendo datos del usuario:', error);
    }
  } else {
    console.log('No hay usuario autenticado');
  }
});