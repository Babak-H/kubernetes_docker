const express = require('express');
const path = require('path');
const bodyParser = require('body-parser');

const app = express();
const port = 3080;

// Placeholder for the data.
const users = [];

app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, '../my-app/build')));

app.get('/api/users', (req, res) => {
  console.log('api/users called!');
  res.json(users);
});

app.post('/api/user', (req, res) => {
  const user = req.body.user;
  console.log('Adding user:::::', user);
  users.push(user);
  res.json('user added');
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../my-app/build/index.html'));
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
