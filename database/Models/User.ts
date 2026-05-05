import { Model } from "objection";
import knexConfig from "../../knexfile";
import knex, { Knex } from "knex";

const environment = process.env.NODE_ENV === "production" ? "production" : "development";
const knexInstance: Knex = knex(knexConfig[environment]);
Model.knex(knexInstance);

class User extends Model {
  static get tableName() {
    return 'users';
  }
}

export default User;