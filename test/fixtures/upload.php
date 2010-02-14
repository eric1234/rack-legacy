Filename: <?php echo $_FILES['test']['name'] ?>

Size: <?php echo $_FILES['test']['size'] ?>

Contents: <?php echo file_get_contents($_FILES['test']['tmp_name']) ?>