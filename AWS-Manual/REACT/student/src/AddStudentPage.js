import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './App.css';

function AddStudentPage() {
  const [student, setStudent] = useState({
    name: '',
    regNo: '',
    age: '',
    dob: '',
    department: ''
  });
  const navigate = useNavigate();

  const handleChange = (e) => {
    setStudent({
      ...student,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    alert(`Student added: ${student.name}, Reg No: ${student.regNo}`);
    navigate('/');
  };

  return (
	  <div className="add-student-page">
    <div className="page-container">
      <h1>Add New Student</h1>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          name="name"
          value={student.name}
          onChange={handleChange}
          placeholder="Name"
          required
        />
        <input
          type="text"
          name="regNo"
          value={student.regNo}
          onChange={handleChange}
          placeholder="Registration Number"
          required
        />
        <input
          type="number"
          name="age"
          value={student.age}
          onChange={handleChange}
          placeholder="Age"
          required
        />
        <input
          type="date"
          name="dob"
          value={student.dob}
          onChange={handleChange}
          placeholder="Date of Birth"
          required
        />
        <input
          type="text"
          name="department"
          value={student.department}
          onChange={handleChange}
          placeholder="Department"
          required
        />
        <button type="submit">Add Student</button>
      </form>
    </div>
   </div>	  
  );
}

export default AddStudentPage;

