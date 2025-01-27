import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import './App.css'; 

function StudentDetailsPage() {
  const [studentDetails, setStudentDetails] = useState(null);
  const navigate = useNavigate();

  // Simulate getting student data from state or global store
  useEffect(() => {
    // This should be fetched from global state or context
    const storedDetails = {
      regNo: '1',
      name: 'Delson',
      age: 25,
      dob: '1999-01-01',
      department: 'Computer Science',
    };
    setStudentDetails(storedDetails);
  }, []);

  if (!studentDetails) {
    return <p>Loading...</p>;
  }

  return (
	  <div className="student-details-page">
    <div className="student-details">
      <h2>Student Details</h2>
      <p><strong>Name:</strong> {studentDetails.name}</p>
      <p><strong>Registration Number:</strong> {studentDetails.regNo}</p>
      <p><strong>Age:</strong> {studentDetails.age}</p>
      <p><strong>Date of Birth:</strong> {studentDetails.dob}</p>
      <p><strong>Department:</strong> {studentDetails.department}</p>
      <button onClick={() => navigate('/')}>Back to Home</button>
    </div>
   </div>	  
  );
}

export default StudentDetailsPage;
