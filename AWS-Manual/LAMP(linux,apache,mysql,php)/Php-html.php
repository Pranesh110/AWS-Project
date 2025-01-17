<?php
$servername = "localhost";
$username = "root";
$password = "";  // MySQL root password (empty if not set)
$dbname = "student_db";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$reg_no = "";
$name = "";
$age = "";
$student_id = "";
$message = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['submit'])) {
        // Handle form submission to add a new student
        $reg_no = $_POST['reg_no'];
        $name = $_POST['name'];
        $age = $_POST['age'];
        $student_id = $_POST['student_id'];

        // Insert new student data into the database
        $sql = "INSERT INTO students (reg_no, name, age, student_id) 
                VALUES ('$reg_no', '$name', $age, '$student_id')";
        
        if ($conn->query($sql) === TRUE) {
            $message = "New student added successfully!";
        } else {
            $message = "Error: " . $sql . "<br>" . $conn->error;
        }
    } else if (isset($_POST['fetch'])) {
        // Handle form submission to fetch student details based on reg_no
        $reg_no = $_POST['reg_no'];

        // Fetch student data based on reg_no
        $sql = "SELECT * FROM students WHERE reg_no = '$reg_no'";
        $result = $conn->query($sql);

        if ($result->num_rows > 0) {
            // Fetching the data
            $row = $result->fetch_assoc();
            $name = $row['name'];
            $age = $row['age'];
            $student_id = $row['student_id'];
        } else {
            $message = "No student found with this registration number!";
        }
    }
}

$conn->close();
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Registration and Lookup</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
    <style>
        /* Set office background image */
        body {
    background-image: url('../image/office.jpg');
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
    color: white;
    font-family: 'Poppins', sans-serif;
    margin: 0;
    padding: 0;
    height: 100vh;
    overflow-y: auto; /* Allow scrolling */
}

h1, h2, p {
    text-align: center;
    color: #ffcc00; /* Bright yellow color for titles */
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.6);
}

form {
    max-width: 600px;
    margin: 20px auto;
    background-color: rgba(0, 0, 0, 0.6);
    padding: 20px;
    border-radius: 10px;
}

label, input {
    display: block;
    margin: 10px 0;
    width: 100%;
    padding: 10px;
    font-size: 1rem;
}

button {
    background-color: #4CAF50;
    color: white;
    padding: 10px 20px;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    width: 100%;
    font-size: 1.2rem;
}

button:hover {
    background-color: #45a049;
}

/* Ensure student details section is scrollable */
.student-details {
    background-color: rgba(0, 0, 0, 0.6);
    color: #ffcc00;
    padding: 20px;
    margin-top: 20px;
    border-radius: 10px;
    font-size: 1.2rem;
    overflow-y: auto;  /* Make the student details section scrollable if content overflows */
}

.student-details p {
    font-weight: bold;
    margin: 10px 0;
}

        .message {
            font-size: 1.2rem;
            font-weight: 500;
            margin: 10px 0;
            color: #ffcc00;
        }

    </style>
</head>
<body>
    <h1>Student Registration and Lookup</h1>

    <!-- Form to Add a New Student -->
    <h2>Add New Student</h2>
    <form method="POST" action="">
        <label for="reg_no">Registration Number:</label>
        <input type="text" id="reg_no" name="reg_no" required>
        
        <label for="name">Name:</label>
        <input type="text" id="name" name="name" required>
        
        <label for="age">Age:</label>
        <input type="number" id="age" name="age" required>
        
        <label for="student_id">Student ID:</label>
        <input type="text" id="student_id" name="student_id" required>
        
        <button type="submit" name="submit">Add Student</button>
    </form>

    <!-- Form to Fetch Student Details by Registration Number -->
    <h2>Search for Student by Registration Number</h2>
    <form method="POST" action="">
        <label for="reg_no">Registration Number:</label>
        <input type="text" id="reg_no" name="reg_no" required>
        <button type="submit" name="fetch">Fetch Details</button>
    </form>

    <!-- Display message after form submission -->
    <?php if (!empty($message)) { ?>
        <div class="message"><?php echo $message; ?></div>
    <?php } ?>

    <!-- Display student details if found -->
    <?php if (!empty($name)) { ?>
        <div class="student-details">
            <h2>Student Details:</h2>
            <p><strong>Name:</strong> <?php echo $name; ?></p>
            <p><strong>Age:</strong> <?php echo $age; ?></p>
            <p><strong>Student ID:</strong> <?php echo $student_id; ?></p>
        </div>
    <?php } ?>
</body>
</html>
