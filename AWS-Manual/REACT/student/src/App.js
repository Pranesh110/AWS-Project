import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import HomePage from './HomePage';
import AddStudentPage from './AddStudentPage';
import StudentDetailsPage from './StudentDetailsPage'; // Import the new page
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/add-student" element={<AddStudentPage />} />
          <Route path="/student-details" element={<StudentDetailsPage />} /> {/* New route */}
        </Routes>
      </div>
    </Router>
  );
}

export default App;

