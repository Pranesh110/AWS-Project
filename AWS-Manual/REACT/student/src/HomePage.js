import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './App.css'; // Import the CSS file for styles

function HomePage() {
  const [regNo, setRegNo] = useState('');
  const [studentDetails, setStudentDetails] = useState(null);
  const navigate = useNavigate();

  const handleSearch = async () => {
    // Simulate an API call to fetch student details
    const studentData = {
      regNo: '1',
      name: 'Delson',
      age: 25,
      dob: '1999-01-01',
      department: 'Computer Science',
    };

    // Simulate fetching data by registration number
    if (regNo === studentData.regNo) {
      setStudentDetails(studentData);
      navigate('/student-details');
    } else {
      alert('Student not found!');
    }
  };

  return (
	<div className="home-page">  
    <div className="page-container">
      <h1>Welcome to the Student Registration Portal</h1>
      <div className="search-section">
        <input
          type="text"
          value={regNo}
          onChange={(e) => setRegNo(e.target.value)}
          placeholder="Enter Registration Number"
        />
        <button onClick={handleSearch}>Fetch Student Details</button>
      </div>
      <div className="add-student">
        <button onClick={() => navigate('/add-student')}>Add New Student</button>
      </div>
    </div>
   </div>	  
  );
}

export default HomePage;

